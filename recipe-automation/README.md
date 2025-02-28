1. recipe-automation-dev-split-file
Purpose: Splits large files into smaller chunks for parallel processing
Triggered when: A new file is uploaded to S3
Runtime: Python 3.9
2. recipe-automation-dev-process-chunk
Purpose: Processes individual chunks of the split file
Triggered when: After file splitting is complete
Runtime: Python 3.9
3. recipe-automation-dev-recipe-processor
Purpose: Main processor for handling recipes/files
Triggered when: For small files that don't need splitting
Runtime: Python 3.9
4. recipe-automation-dev-merge-results
Purpose: Combines processed chunks back together
Triggered when: All chunks have been processed
Runtime: Python 3.9
5. recipe-automation-dev-archive-creator
Purpose: Creates the final archived/compressed version
Triggered when: Merging is complete
Runtime: Python 3.9


Upload → Split File → Process Chunks → Merge Results → Create Archive
           ↓              ↓              ↓               ↓
    split-file → process-chunk → merge-results → archive-creator
                     ↑
         recipe-processor


         
