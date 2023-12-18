unit funciones;

interface

uses System.Json, System.RegularExpressions, IdHashMessageDigest, System.Classes, System.SysUtils, System.StrUtils, System.AnsiStrings;

function json_array(OldValue: PAnsiChar; NewValue: PAnsiChar): PAnsiChar; cdecl; export;
function json_group_object(Objecto: PAnsiChar; Name: PAnsiChar; Value: PAnsiChar): PAnsiChar; cdecl; export;
function MD5Sum(Value: PAnsiChar): PAnsiChar; cdecl; export;
function ib_util_malloc(l: integer): pointer; cdecl; external 'libib_util.so';

implementation

procedure log(cadena: String);
var
  RutaFichero: String;
  F: TextFile;
begin
  RutaFichero := '/tmp/debug.log';
  AssignFile(F, RutaFichero);
  if not FileExists(RutaFichero)
  then
    Rewrite(F)
  else
    Append(F);
  try
    Writeln(F, TimeToStr(Time) + ' ' + cadena);
  finally
    CloseFile(F);
  end;
end;

function MD5Sum(Value: PAnsiChar): PAnsiChar;
var
  hash: string;
begin
  try
    With TIdHashMessageDigest5.Create do
    begin
      hash := HashStringAsHex(Value);
      Free;
    end;
    Result := ib_util_malloc(Length(hash) + 1);
    System.AnsiStrings.StrPCopy(Result, AnsiString(hash));
    log(hash);
  except
    on E: Exception do
      log(E.Message);
  end;
end;

function ParseValue(Value: String): TJSONValue;
begin
  if UpperCase(Value) = 'NULL'
  then
    Result := TJSONNull.Create
  else if StrToIntDef(Value, -1) <> -1
  then
    Result := TJSONNumber.Create(StrToInt(Value))
  else if (UpperCase(Value) = 'TRUE') OR (UpperCase(Value) = 'FALSE')
  then
    Result := TJSONBool.Create(StrToBool(Value))
  else
    Result := TJSONString.Create(Value);
end;

function json_array(OldValue: PAnsiChar; NewValue: PAnsiChar): PAnsiChar;
var
  AOldValue: String;
  ANewValue: String;
  JsonArr: TJSONArray;
begin
  JsonArr := TJSONArray.Create;
  try
    try
      AOldValue := String(AnsiString(OldValue));
      ANewValue := String(AnsiString(NewValue));
      JsonArr.AddElement(ParseValue(AOldValue));
      JsonArr.AddElement(ParseValue(ANewValue));
      log(JsonArr.ToString);
      Result := ib_util_malloc(Length(JsonArr.ToString) + 1);
      System.AnsiStrings.StrPCopy(Result, AnsiString(JsonArr.ToString));
    except
      on E: Exception do
        log(E.Message);
    end;
  finally
    JsonArr.Free;
  end;

end;

function json_group_object(Objecto: PAnsiChar; Name: PAnsiChar; Value: PAnsiChar): PAnsiChar;
var
  AName: String;
  AObjecto: String;
  AValue: String;
  JsonObj: TJSONObject;
  JSONValue: TJSONValue;
  JSONObjeto: TJSONValue;
begin
  try
    try
      AObjecto := String(AnsiString(Objecto));
      AName := String(AnsiString(Name));
      AValue := String(AnsiString(Value));
      JSONObjeto := TJSONObject.ParseJSONValue(AObjecto);
      if JSONObjeto is TJSONObject
      then
        JsonObj := JSONObjeto as TJSONObject
      else
        JsonObj := TJSONObject.Create;
      JSONValue := TJSONObject.ParseJSONValue(AValue);
      if JSONValue is TJSONArray
      then
        JsonObj.AddPair(AName, JSONValue as TJSONArray);
      if JSONValue is TJSONObject
      then
        JsonObj.AddPair(AName, JSONValue as TJSONObject);
      Result := ib_util_malloc(Length(JsonObj.ToString) + 1);
      System.AnsiStrings.StrPCopy(Result, AnsiString(JsonObj.ToString));
    except
      on E: Exception do
        log(E.Message);
    end;
  finally
    if JsonObj <> nil
    then
      JsonObj.Free;
  end;
end;

end.
