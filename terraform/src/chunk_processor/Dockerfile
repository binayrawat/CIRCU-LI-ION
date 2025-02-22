FROM public.ecr.aws/lambda/nodejs:18

# Install system dependencies
RUN yum install -y zip unzip

# Copy function code
COPY index.js package.json ./
RUN npm install

# Set the CMD
CMD ["index.handler"] 