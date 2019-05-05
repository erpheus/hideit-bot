### IMPORTANT: As this file changes the import path, it should be imported before anything else

import sys
import os
# Add deps folder to import path for non-default libraries
sys.path.insert(
    0,
    os.path.normpath(
    	os.path.join(
    		os.path.dirname(os.path.realpath(__file__)),
    		"..",
    		"deps"
    	)
    )
)

import logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                     level=logging.INFO)
