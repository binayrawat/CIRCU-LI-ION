// Load required tools
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const AdmZip = require('adm-zip');
const stream = require('stream');
const { promisify } = require('util');

const pipeline = promisify(stream.pipeline);
const CHUNK_SIZE = 50 * 1024 * 1024; // 50MB chunks

// Main function that runs when files are uploaded
exports.handler = async (event) => {
    try {
        console.log('Event received:', JSON.stringify(event, null, 2));
        
        const bucket = event.Records[0].s3.bucket.name;
        const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
        
        console.log('Starting to process:', { bucket, key });

        // Skip if already processed
        if (key.startsWith('processed/')) {
            console.log('Skipping already processed file');
            return {
                statusCode: 200,
                body: JSON.stringify({ message: 'Already processed' })
            };
        }

        // Get file metadata
        console.log('Getting file metadata...');
        const headObject = await s3.headObject({ 
            Bucket: bucket, 
            Key: key 
        }).promise();
        
        const fileSize = headObject.ContentLength;
        console.log('File size:', fileSize, 'bytes');

        // For large files (>500MB)
        if (fileSize > 500 * 1024 * 1024) {
            console.log('Large file detected, using streaming approach');
            
            // Create read stream
            const readStream = s3.getObject({
                Bucket: bucket,
                Key: key
            }).createReadStream();

            // Create write stream for temporary file
            const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;
            console.log('Will save to:', processedKey);

            // Initialize multipart upload
            console.log('Initializing multipart upload...');
            const multipartUpload = await s3.createMultipartUpload({
                Bucket: bucket,
                Key: processedKey,
                ContentType: 'application/zip',
                Metadata: {
                    'processed-date': new Date().toISOString(),
                    'original-file': key,
                    'original-size': fileSize.toString()
                }
            }).promise();

            try {
                const uploadId = multipartUpload.UploadId;
                const parts = [];
                let partNumber = 1;
                let currentBuffer = Buffer.from([]);

                // Process the stream
                await new Promise((resolve, reject) => {
                    readStream.on('data', async chunk => {
                        try {
                            currentBuffer = Buffer.concat([currentBuffer, chunk]);
                            
                            // If buffer is large enough, upload as a part
                            if (currentBuffer.length >= CHUNK_SIZE) {
                                console.log(`Uploading part ${partNumber}...`);
                                const partBuffer = currentBuffer;
                                currentBuffer = Buffer.from([]);

                                const uploadResult = await s3.uploadPart({
                                    Bucket: bucket,
                                    Key: processedKey,
                                    PartNumber: partNumber,
                                    UploadId: uploadId,
                                    Body: partBuffer
                                }).promise();

                                parts.push({
                                    PartNumber: partNumber,
                                    ETag: uploadResult.ETag
                                });
                                
                                partNumber++;
                                console.log(`Part ${partNumber-1} uploaded`);
                            }
                        } catch (error) {
                            reject(error);
                        }
                    });

                    readStream.on('end', async () => {
                        try {
                            // Upload any remaining data
                            if (currentBuffer.length > 0) {
                                console.log('Uploading final part...');
                                const uploadResult = await s3.uploadPart({
                                    Bucket: bucket,
                                    Key: processedKey,
                                    PartNumber: partNumber,
                                    UploadId: uploadId,
                                    Body: currentBuffer
                                }).promise();

                                parts.push({
                                    PartNumber: partNumber,
                                    ETag: uploadResult.ETag
                                });
                            }

                            // Complete multipart upload
                            console.log('Completing multipart upload...');
                            await s3.completeMultipartUpload({
                                Bucket: bucket,
                                Key: processedKey,
                                UploadId: uploadId,
                                MultipartUpload: { Parts: parts }
                            }).promise();

                            resolve();
                        } catch (error) {
                            reject(error);
                        }
                    });

                    readStream.on('error', error => {
                        console.error('Stream error:', error);
                        reject(error);
                    });
                });

                console.log('Large file processing completed successfully');

            } catch (error) {
                console.error('Error during multipart upload:', error);
                // Abort multipart upload on error
                await s3.abortMultipartUpload({
                    Bucket: bucket,
                    Key: processedKey,
                    UploadId: multipartUpload.UploadId
                }).promise();
                throw error;
            }

        } else {
            // Original code for small files
            console.log('Processing small file normally');
            const file = await s3.getObject({
                Bucket: bucket,
                Key: key
            }).promise();
            
            const zip = new AdmZip();
            zip.addFile(key.split('/').pop(), file.Body);
            
            const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;
            await s3.putObject({
                Bucket: bucket,
                Key: processedKey,
                Body: zip.toBuffer(),
                ContentType: 'application/zip',
                Metadata: {
                    'processed-date': new Date().toISOString(),
                    'original-file': key
                }
            }).promise();
        }

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Success',
                file: key
            })
        };

    } catch (error) {
        console.error('Processing error:', {
            error: error.message,
            stack: error.stack,
            event: JSON.stringify(event, null, 2)
        });
        throw error;
    }
}; 