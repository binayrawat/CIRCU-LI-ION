// Load required tools
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const archiver = require('archiver');  // More efficient than adm-zip for large files
const stream = require('stream');
const { promisify } = require('util');

const pipeline = promisify(stream.pipeline);
const CHUNK_SIZE = 10 * 1024 * 1024; // 10MB chunks for better memory management
const MAX_RETRIES = 3;
const SMALL_FILE_THRESHOLD = 100 * 1024 * 1024; // 100MB

async function processSmallFile(bucket, key) {
    console.log('Processing small file normally');
    const file = await s3.getObject({ Bucket: bucket, Key: key }).promise();
    const archive = archiver('zip', { zlib: { level: 9 } });
    const passThrough = new stream.PassThrough();
    
    archive.pipe(passThrough);
    archive.append(file.Body, { name: key.split('/').pop() });
    archive.finalize();

    const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;
    await s3.upload({
        Bucket: bucket,
        Key: processedKey,
        Body: passThrough,
        ContentType: 'application/zip'
    }).promise();

    return processedKey;
}

async function processLargeFile(bucket, key, fileSize) {
    console.log('Processing large file with streaming');
    const processedKey = `processed/${key.split('/').pop().split('.')[0]}.zip`;

    // Initialize multipart upload
    const multipartUpload = await s3.createMultipartUpload({
        Bucket: bucket,
        Key: processedKey,
        ContentType: 'application/zip',
        Metadata: {
            'original-size': fileSize.toString(),
            'processing-date': new Date().toISOString()
        }
    }).promise();

    try {
        const parts = [];
        let partNumber = 1;
        let position = 0;

        while (position < fileSize) {
            const end = Math.min(position + CHUNK_SIZE, fileSize);
            console.log(`Processing chunk ${partNumber}: ${position}-${end-1}`);

            let retries = 0;
            while (retries < MAX_RETRIES) {
                try {
                    // Get and process chunk
                    const chunk = await s3.getObject({
                        Bucket: bucket,
                        Key: key,
                        Range: `bytes=${position}-${end-1}`
                    }).promise();

                    // Create zip stream for chunk
                    const archive = archiver('zip', { zlib: { level: 9 } });
                    const passThrough = new stream.PassThrough();
                    archive.pipe(passThrough);
                    
                    archive.append(chunk.Body, { 
                        name: `part_${partNumber}.json`,
                        date: new Date()
                    });
                    archive.finalize();

                    // Upload part
                    const uploadResult = await s3.uploadPart({
                        Bucket: bucket,
                        Key: processedKey,
                        PartNumber: partNumber,
                        UploadId: multipartUpload.UploadId,
                        Body: passThrough
                    }).promise();

                    parts.push({
                        PartNumber: partNumber,
                        ETag: uploadResult.ETag
                    });

                    break; // Success, exit retry loop
                } catch (error) {
                    retries++;
                    if (retries === MAX_RETRIES) throw error;
                    console.log(`Retry ${retries} for chunk ${partNumber}`);
                    await new Promise(resolve => setTimeout(resolve, 1000 * retries));
                }
            }

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

        return processedKey;
    } catch (error) {
        console.error('Error during large file processing:', error);
        await s3.abortMultipartUpload({
            Bucket: bucket,
            Key: processedKey,
            UploadId: multipartUpload.UploadId
        }).promise();
        throw error;
    }
}

// Main function that runs when files are uploaded
exports.handler = async (event) => {
    try {
        console.log('Event:', JSON.stringify(event, null, 2));
        
        const bucket = event.Records[0].s3.bucket.name;
        const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
        
        if (key.startsWith('processed/')) {
            console.log('Skipping processed file');
            return { statusCode: 200, body: 'Skipped processed file' };
        }

        // Get file metadata
        const headObject = await s3.headObject({ Bucket: bucket, Key: key }).promise();
        const fileSize = headObject.ContentLength;
        console.log(`Processing file: ${key}, Size: ${fileSize} bytes`);

        // Choose processing method based on file size
        const processedKey = fileSize > SMALL_FILE_THRESHOLD 
            ? await processLargeFile(bucket, key, fileSize)
            : await processSmallFile(bucket, key);

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Success',
                originalFile: key,
                processedFile: processedKey,
                size: fileSize
            })
        };

    } catch (error) {
        console.error('Processing error:', {
            message: error.message,
            stack: error.stack,
            event: JSON.stringify(event, null, 2)
        });
        throw error;
    }
}; 