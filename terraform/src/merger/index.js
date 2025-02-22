const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const archiver = require('archiver');
const stream = require('stream');

exports.handler = async (event) => {
    const { bucket, key, totalChunks } = event;
    const archive = archiver('zip', { zlib: { level: 9 } });
    const passThrough = new stream.PassThrough();
    
    archive.pipe(passThrough);

    // Merge all chunks
    for (let i = 0; i < totalChunks; i++) {
        const chunkKey = `processed/chunks/${key}_${i}.zip`;
        const chunk = await s3.getObject({
            Bucket: bucket,
            Key: chunkKey
        }).promise();
        
        archive.append(chunk.Body, { name: `part_${i}.zip` });
        
        // Clean up chunk
        await s3.deleteObject({
            Bucket: bucket,
            Key: chunkKey
        }).promise();
    }

    await archive.finalize();

    // Upload final merged file
    const finalKey = `processed/${key.split('/').pop()}`;
    await s3.upload({
        Bucket: bucket,
        Key: finalKey,
        Body: passThrough,
        ContentType: 'application/zip'
    }).promise();

    return {
        status: 'completed',
        bucket,
        key: finalKey
    };
}; 