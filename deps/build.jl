c=`pip install pexpect unidecode jsonrpclib`
try
    run(c)
catch err
    error("Installing necessary Python packages failed via 'pip' failed. Try manually installing the pexpect, unidecode, and jsonrpclib libraries, or using `pip` with sudo")
end