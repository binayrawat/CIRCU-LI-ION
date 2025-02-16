// Load required tools
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const AdmZip = require('adm-zip');

// Main function that runs when files are uploaded
exports.handler = async (event) => {
    try {
        // Get file details
        const bucket = event.Records[0].s3.bucket.name;
        const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
        
        console.log(`Processing: ${key}`);

        // Skip if already processed
        if (key.startsWith('processed/')) {
            return {
                statusCode: 200,
                body: JSON.stringify({ message: 'Already processed' })
            };
        }

        // Get the file from S3
        const file = await s3.getObject({
            Bucket: bucket,
            Key: key
        }).promise();

        // Zip the file
        const zip = new AdmZip();
        zip.addFile(key, file.Body);

        // Save zipped file back to S3
        await s3.putObject({
            Bucket: bucket,
            Key: `processed/${key.split('.')[0]}.zip`,
            Body: zip.toBuffer(),
            ContentType: 'application/zip',
            Metadata: {
                'processed-date': new Date().toISOString(),
                'original-file': key
            }
        }).promise();

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