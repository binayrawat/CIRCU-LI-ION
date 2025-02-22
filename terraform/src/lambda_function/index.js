// Load required tools
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const AdmZip = require('adm-zip');

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
            return {
                statusCode: 200,
                body: JSON.stringify({ message: 'Already processed' })
            };
        }

        // Get the file from S3
        console.log('Getting file from S3');
        const file = await s3.getObject({
            Bucket: bucket,
            Key: key
        }).promise();
        console.log('File retrieved successfully');

        // Zip the file
        console.log('Creating zip file');
        const zip = new AdmZip();
        zip.addFile(key.split('/').pop(), file.Body);  // Use just the filename

        // Save zipped file back to S3
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
        console.log('Zip file saved successfully');

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Success',
                file: key,
                processedFile: processedKey
            })
        };
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
}; 