function CalculateMd5($path)
{
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($path)))
}

function WriteAmigaTextLines($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}

# resolve paths
$systemPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("System")
$validateSystemScriptPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("validate_system")

$validateSystemScriptLines = @()

$systemFiles = Get-ChildItem -Path $systemPath -Recurse | where { ! $_.PSIsContainer -and $_.Name -notmatch '^__uae__' }

foreach ($systemFile in $systemFiles)
{
	$systemFileMd5 = (CalculateMd5 $systemFile.FullName).ToLower().Replace('-', ' ')
	
	$amigaSystemFilePath = $systemFile.FullName.Substring($systemPath.Length + 1, $systemFile.FullName.Length - $systemPath.Length - 1).Replace('\', '/')
	
	$validateSystemScriptLines += @(
		('IF EXISTS "' + $amigaSystemFilePath + '"'),
		('  SET md5 `C:md5 "' + $amigaSystemFilePath + '"`'),
		('  IF NOT "$md5" eq "' + $systemFileMd5 + '"'),
		('    ECHO "File ''' + $amigaSystemFilePath + ''' has invalid md5 checksum"'),
		"  ENDIF"
		'ELSE',
		('  ECHO "File ''' + $amigaSystemFilePath + ''' doesn''t exist"'),
		'ENDIF')
}

WriteAmigaTextLines $validateSystemScriptPath $validateSystemScriptLines
