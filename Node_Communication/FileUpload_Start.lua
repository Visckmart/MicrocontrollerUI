file.open('<filename>', 'w+');
x = '';
i = 0;
t = {};
uart.on('data', <filesize>, function (d)
    x = d;
    i = i + #d;
    table.insert(t, {d, #d});
    file.write(d:match('^%s*(.*)%s*$'));
    uart.on('data')
end, 0)
