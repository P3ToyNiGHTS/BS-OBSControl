<#
    OBSControl 릴리스 빌드 스크립트.

    OBSControl 은 게임 버전을 브랜치로 나눈다 (master = 1.40.x, 1.29.1 = 1.29.1).
    이 스크립트는 "현재 체크아웃된 브랜치" 를 Release 로 빌드하고
    dist\OBSControl-<Version>-bs<GameVersion>.zip 으로 패키징한다.
    각 zip 은 압축 해제 시 곧바로 Plugins\OBSControl.dll 구조가 되도록 담는다.

    두 게임 버전을 릴리스하려면 각 브랜치에서 한 번씩 실행한다
    (BeatSaberDir 을 그 게임 설치로 맞춘 뒤). -Publish 로 실행하면 같은
    v<Version> 릴리스에 자산을 계속 덧붙인다(이미 있으면 --clobber).

    사용 예:
      # 현재 브랜치 빌드 + dist\ 에 zip 생성
      pwsh tools\build-release.ps1

      # GitHub 릴리스 v<Version> 생성/업로드 (태그는 현재 HEAD)
      pwsh tools\build-release.ps1 -Publish

    OBSControl 은 `dotnet build` 가 ILRepack 단계에서 죽으므로 반드시
    full-framework MSBuild 로 빌드한다(기본 경로는 VS 2022 Build Tools).
#>
[CmdletBinding()]
param(
    # 릴리스 버전. 생략 시 Directory.Build.props 의 <Version> 사용.
    [string]$Version,
    # 자산 파일명 접미사 bs<GameVersion>. 생략 시 props 의 <GameVersion> 사용.
    [string]$GameVersion,
    # 지정 시 gh 로 릴리스 생성/업로드.
    [switch]$Publish,
    # -Publish 시 릴리스 노트 마크다운 파일 (없으면 자동 생성 노트).
    [string]$NotesFile,
    # -Publish 시 태그가 가리킬 커밋. 기본은 현재 HEAD.
    [string]$Target,
    # full-framework MSBuild.exe 경로.
    [string]$MSBuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$asmName  = 'OBSControl'
$propsPath = Join-Path $repoRoot 'OBSControl\Directory.Build.props'
$props = [xml](Get-Content $propsPath)
$pg = $props.Project.PropertyGroup | Where-Object { $_.Version } | Select-Object -First 1

if ([string]::IsNullOrWhiteSpace($Version))     { $Version = ([string]$pg.Version).Trim() }
if ([string]::IsNullOrWhiteSpace($GameVersion)) { $GameVersion = ([string]$pg.GameVersion).Trim() }
if ([string]::IsNullOrWhiteSpace($Version))     { throw "Directory.Build.props 에서 <Version> 을 찾지 못했습니다." }
Write-Host "Version=$Version  GameVersion=$GameVersion  Branch=$(git branch --show-current)" -ForegroundColor Cyan

if (-not (Test-Path $MSBuild)) { throw "MSBuild 를 찾을 수 없습니다: $MSBuild (-MSBuild 로 경로 지정)" }

# ---- 빌드 (Release) ----
Write-Host "`n=== Build Release ===" -ForegroundColor Yellow
& $MSBuild 'OBSControl\OBSControl.csproj' -t:Restore,Build -p:Configuration=Release -nologo -v:minimal
if ($LASTEXITCODE -ne 0) { throw "빌드 실패 (BeatSaberDir 이 이 브랜치의 게임 설치를 가리키는지 확인)" }

$dll = Join-Path $repoRoot "OBSControl\bin\Release\net472\Merged\$asmName.dll"
if (-not (Test-Path $dll)) { throw "산출물 없음: $dll" }

# ---- 패키징 ----
$distDir = Join-Path $repoRoot 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
$stage = Join-Path $distDir "_pkg-$GameVersion"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'Plugins') | Out-Null
Copy-Item $dll (Join-Path $stage 'Plugins')

$zip = Join-Path $distDir "$asmName-$Version-bs$GameVersion.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
Remove-Item $stage -Recurse -Force

$size = [math]::Round((Get-Item $zip).Length / 1KB, 1)
Write-Host "  -> $zip (${size} KB)" -ForegroundColor Green

# ---- GitHub 릴리스 (선택) ----
if ($Publish) {
    $tag = "v$Version"
    Write-Host "`n=== GitHub 릴리스: $tag ===" -ForegroundColor Yellow

    $notesArgs = if ($NotesFile -and (Test-Path $NotesFile)) { @('--notes-file', $NotesFile) } else { @('--generate-notes') }
    if ([string]::IsNullOrWhiteSpace($Target)) { $Target = (git rev-parse HEAD).Trim() }
    Write-Host "태그 대상 커밋: $Target" -ForegroundColor Cyan

    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        gh release view $tag 1>$null 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "릴리스 $tag 존재 -> 자산 업로드(--clobber)" -ForegroundColor Cyan
            gh release upload $tag $zip --clobber
        } else {
            Write-Host "릴리스 $tag 생성" -ForegroundColor Cyan
            gh release create $tag $zip --title $Version --target $Target @notesArgs
        }
        $ghExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $eap
    }
    if ($ghExit -ne 0) { throw "gh 릴리스 실패 (exit $ghExit)" }
    Write-Host "릴리스 완료: $tag" -ForegroundColor Green
}
