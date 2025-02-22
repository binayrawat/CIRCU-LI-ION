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
        
        console.log('Processing file:', { bucket, key });

        // Skip if already processed
        if (key.startsWith('processed/')) {
            console.log('Skipping already processed file');
            return {
                statusCode: 200,
                body: JSON.stringify({ message: 'Already processed' })
            };
        }

        // Get file metadata
        const headObject = await s3.headObject({ Bucket: bucket, Key: key }).promise();
        const fileSize = headObject.ContentLength;
        console.log('File size:', fileSize);

        // Initialize multipart upload for the zip file
        const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;
        const multipartUpload = await s3.createMultipartUpload({
            Bucket: bucket,
            Key: processedKey,
            ContentType: 'application/zip'
        }).promise();

        try {
            const parts = [];
            let partNumber = 1;
            let position = 0;

            while (position < fileSize) {
                const end = Math.min(position + CHUNK_SIZE, fileSize);
                console.log(`Processing chunk ${partNumber}: bytes ${position} to ${end}`);

                // Get chunk of original file
                const range = `bytes=${position}-${end-1}`;
                const chunk = await s3.getObject({
                    Bucket: bucket,
                    Key: key,
                    Range: range
                }).promise();

                // Create zip for this chunk
                const zip = new AdmZip();
                zip.addFile(`chunk_${partNumber}.json`, chunk.Body);
                const zipBuffer = zip.toBuffer();

                // Upload zip chunk
                const uploadResult = await s3.uploadPart({
                    Bucket: bucket,
                    Key: processedKey,
                    PartNumber: partNumber,
                    UploadId: multipartUpload.UploadId,
                    Body: zipBuffer
                }).promise();

                parts.push({
                    PartNumber: partNumber,
                    ETag: uploadResult.ETag
                });

                position = end;
                partNumber++;
            }

            // Complete multipart upload
            await s3.completeMultipartUpload({
                Bucket: bucket,
                Key: processedKey,
                UploadId: multipartUpload.UploadId,
                MultipartUpload: { Parts: parts }
            }).promise();

            console.log('Processing completed successfully');
            return {
                statusCode: 200,
                body: JSON.stringify({
                    message: 'Success',
                    file: key,
                    processedFile: processedKey
                })
            };

        } catch (error) {
            console.error('Error during processing:', error);
            // Abort multipart upload on error
            await s3.abortMultipartUpload({
                Bucket: bucket,
                Key: processedKey,
                UploadId: multipartUpload.UploadId
            }).promise();
            throw error;
        }
    } catch (error) {
        console.error('Processing error:', error);
        throw error;
    }
}; 