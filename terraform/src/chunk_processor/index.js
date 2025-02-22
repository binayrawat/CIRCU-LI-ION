const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const archiver = require('archiver');
const stream = require('stream');

exports.handler = async (event) => {
    const { bucket, key, start, end, chunkId } = event;
    
    // Get chunk
    const chunk = await s3.getObject({
        Bucket: bucket,
        Key: key,
        Range: `bytes=${start}-${end-1}`
    }).promise();

    // Create zip
    const archive = archiver('zip', { zlib: { level: 9 } });
    const passThrough = new stream.PassThrough();
    
    archive.pipe(passThrough);
    archive.append(chunk.Body, { name: `chunk_${chunkId}.json` });
    await archive.finalize();

    // Upload chunk
    await s3.putObject({
        Bucket: bucket,
        Key: `processed/chunks/${key}_${chunkId}.zip`,
        Body: passThrough,
        Metadata: {
            ChunkId: chunkId.toString(),
            OriginalStart: start.toString(),
            OriginalEnd: end.toString()
        }
    }).promise();

    return { chunkId, status: 'completed' };
}; 