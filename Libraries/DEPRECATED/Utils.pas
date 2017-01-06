unit Utils;

interface

uses
  Windows, Math, SysUtils;



procedure WaitForReturn;

implementation



procedure WaitForReturn;
begin
  Writeln('Press return to continue...');
  while GetAsyncKeyState(VK_RETURN) and $8000 <> 0 do
    Sleep(50);

  while GetAsyncKeyState(VK_RETURN) and $8000 = 0 do
    Sleep(50);
end;

end.
