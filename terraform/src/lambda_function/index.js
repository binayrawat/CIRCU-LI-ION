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
        
        // Get file details
        const bucket = event.Records[0].s3.bucket.name;
        const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
        
        console.log('Processing file:', { bucket, key });

        // Skip if already processed
        if (key.startsWith('processed/')) {
            console.log('Skipping already processed file');
            return;
        }

        // Get file metadata
        const headObject = await s3.headObject({ Bucket: bucket, Key: key }).promise();
        const fileSize = headObject.ContentLength;
        console.log('File size:', fileSize);

        if (fileSize > 500 * 1024 * 1024) { // If file is larger than 500MB
            console.log('Processing large file in chunks');
            
            const zip = new AdmZip();
            let position = 0;
            let chunks = [];

            while (position < fileSize) {
                const end = Math.min(position + CHUNK_SIZE, fileSize);
                console.log(`Processing chunk: ${position} to ${end}`);

                const chunk = await s3.getObject({
                    Bucket: bucket,
                    Key: key,
                    Range: `bytes=${position}-${end-1}`
                }).promise();

                chunks.push(chunk.Body);
                position = end;
            }

            console.log('Combining chunks and creating zip');
            const completeBuffer = Buffer.concat(chunks);
            zip.addFile(key.split('/').pop(), completeBuffer);

            console.log('Uploading zip file in chunks');
            const zipBuffer = zip.toBuffer();
            const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;

            // Upload zip in chunks if it's large
            if (zipBuffer.length > CHUNK_SIZE) {
                const upload = await s3.createMultipartUpload({
                    Bucket: bucket,
                    Key: processedKey,
                    ContentType: 'application/zip',
                    Metadata: {
                        'processed-date': new Date().toISOString(),
                        'original-file': key,
                        'original-size': fileSize.toString()
                    }
                }).promise();

                const Parts = [];
                let partNumber = 1;
                position = 0;

                while (position < zipBuffer.length) {
                    const end = Math.min(position + CHUNK_SIZE, zipBuffer.length);
                    const chunk = zipBuffer.slice(position, end);

                    console.log(`Uploading zip part ${partNumber}`);
                    const part = await s3.uploadPart({
                        Bucket: bucket,
                        Key: processedKey,
                        PartNumber: partNumber,
                        UploadId: upload.UploadId,
                        Body: chunk
                    }).promise();

                    Parts.push({
                        PartNumber: partNumber,
                        ETag: part.ETag
                    });

                    position = end;
                    partNumber++;
                }

                await s3.completeMultipartUpload({
                    Bucket: bucket,
                    Key: processedKey,
                    UploadId: upload.UploadId,
                    MultipartUpload: { Parts }
                }).promise();

            } else {
                // Upload small zip directly
                await s3.putObject({
                    Bucket: bucket,
                    Key: processedKey,
                    Body: zipBuffer,
                    ContentType: 'application/zip',
                    Metadata: {
                        'processed-date': new Date().toISOString(),
                        'original-file': key,
                        'original-size': fileSize.toString()
                    }
                }).promise();
            }

            console.log('Large file processing completed');
        } else {
            // Original code for smaller files
            console.log('Getting file from S3');
            const file = await s3.getObject({
                Bucket: bucket,
                Key: key
            }).promise();
            
            console.log('Creating zip file');
            const zip = new AdmZip();
            zip.addFile(key.split('/').pop(), file.Body);
            
            const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;
            console.log('Saving zip file to:', processedKey);
            
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

        console.log('Processing completed successfully');
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Success',
                file: key
            })
        };
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
}; 