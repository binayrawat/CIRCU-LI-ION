// Load required tools
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const AdmZip = require('adm-zip');
const stream = require('stream');
const { promisify } = require('util');

const pipeline = promisify(stream.pipeline);

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

        // For files larger than 500MB, use streaming
        if (fileSize > 500 * 1024 * 1024) {
            console.log('Large file detected, using streaming approach');
            
            // Create a read stream from S3
            const s3Stream = s3.getObject({ Bucket: bucket, Key: key }).createReadStream();
            
            // Create a write stream to S3
            const passThrough = new stream.PassThrough();
            const zip = new AdmZip();
            
            // Process the stream in chunks
            let buffer = Buffer.from([]);
            s3Stream.on('data', chunk => {
                buffer = Buffer.concat([buffer, chunk]);
            });

            await new Promise((resolve, reject) => {
                s3Stream.on('end', () => {
                    try {
                        console.log('Stream ended, creating zip');
                        zip.addFile(key.split('/').pop(), buffer);
                        const zipBuffer = zip.toBuffer();
                        
                        const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;
                        console.log('Saving large zip file to:', processedKey);
                        
                        s3.putObject({
                            Bucket: bucket,
                            Key: processedKey,
                            Body: zipBuffer,
                            ContentType: 'application/zip',
                            Metadata: {
                                'processed-date': new Date().toISOString(),
                                'original-file': key,
                                'original-size': fileSize.toString()
                            }
                        }).promise()
                        .then(() => resolve())
                        .catch(err => reject(err));
                    } catch (error) {
                        reject(error);
                    }
                });
                
                s3Stream.on('error', error => reject(error));
            });
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