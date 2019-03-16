print('<control begin>')
local success, error=pcall(function() <command> end)
if not success then
  uart.write(0, 'Error :/\\n'..error)
end
print('<control end>')
