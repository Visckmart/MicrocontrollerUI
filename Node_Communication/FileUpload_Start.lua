file.open('<filename>', 'w+');
uart.on('data', <filesize>, function (d)
    file.write(d:match('^%s*(.*)%s*$'));
    uart.on('data')
    file.close()
end, 0)
