c=`pip install pexpect unidecode jsonrpclib`
try
    run(c)
catch err
    error("Installing necessary Python packages  via 'pip' failed. Try manually installing the pexpect, unidecode, and jsonrpclib Python packages, or using `pip` with sudo")
end