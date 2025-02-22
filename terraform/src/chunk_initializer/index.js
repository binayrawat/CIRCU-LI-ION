const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const bucket = event.bucket;
    const key = event.key;
    const chunkSize = 100 * 1024 * 1024; // 100MB chunks

    // Get file size
    const head = await s3.headObject({ Bucket: bucket, Key: key }).promise();
    const fileSize = head.ContentLength;
    
    // Calculate chunks
    const chunks = [];
    for (let start = 0; start < fileSize; start += chunkSize) {
        const end = Math.min(start + chunkSize, fileSize);
        chunks.push({
            start,
            end,
            bucket,
            key,
            chunkId: Math.floor(start / chunkSize)
        });
    }

    return {
        chunks,
        totalChunks: chunks.length,
        fileSize,
        bucket,
        key
    };
}; 