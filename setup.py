from setuptools import setup, find_packages

setup(
    name="recipe-processor",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "boto3>=1.26.137",
    ],
) 