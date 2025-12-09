# fix-atlas-textures.ps1
# 修复 Spine atlas 文件中的纹理引用编码问题
# 将乱码的纹理文件名替换为正确的日文文件名

$spinePath = "E:\偶像大师\闪耀色彩图片-最终版\spine"
$fixedCount = 0
$errorCount = 0

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Spine Atlas 纹理引用修复脚本" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 获取所有 atlas 文件
$atlasFiles = Get-ChildItem -Path $spinePath -Recurse -Filter "*.atlas"

foreach ($atlasFile in $atlasFiles) {
    try {
        # 获取正确的纹理文件名（目录名 + .png）
        $correctTextureName = $atlasFile.Directory.Name + ".png"
        
        # 检查对应的 png 文件是否存在
        $pngPath = Join-Path $atlasFile.Directory.FullName $correctTextureName
        if (-not (Test-Path $pngPath)) {
            Write-Host "⚠️ 警告: PNG 文件不存在 - $correctTextureName" -ForegroundColor Yellow
            continue
        }
        
        # 读取 atlas 文件内容（使用 UTF-8）
        $bytes = [System.IO.File]::ReadAllBytes($atlasFile.FullName)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        $lines = $content -split "`n"
        
        if ($lines.Length -eq 0) {
            continue
        }
        
        # 检查第一行是否已经是正确的纹理名
        $firstLine = $lines[0].Trim()
        
        if ($firstLine -eq $correctTextureName) {
            # 已经正确，跳过
            continue
        }
        
        # 检查是否是乱码（包含非打印字符或不以【开头也不是正常 png 名）
        $needsFix = $false
        
        # 如果第一行不是正确的纹理名，尝试修复
        if ($firstLine -ne $correctTextureName) {
            # 检查是否是乱码（包含替换字符或其他异常）
            if ($firstLine -match '[\uFFFD]' -or 
                ($firstLine -match '\.png$' -and $firstLine -ne $correctTextureName)) {
                $needsFix = $true
            }
            # 检查第一行是否根本不是 png 文件名格式
            elseif (-not ($firstLine -match '\.png$')) {
                $needsFix = $true
            }
        }
        
        if ($needsFix) {
            Write-Host "🔧 修复: $($atlasFile.FullName)" -ForegroundColor Yellow
            Write-Host "   原始: $firstLine" -ForegroundColor DarkGray
            Write-Host "   修正: $correctTextureName" -ForegroundColor Green
            
            # 替换第一行
            $lines[0] = $correctTextureName
            $newContent = $lines -join "`n"
            
            # 写回文件（UTF-8 无 BOM）
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($atlasFile.FullName, $newContent, $utf8NoBom)
            
            $fixedCount++
        }
    }
    catch {
        Write-Host "❌ 错误处理文件: $($atlasFile.FullName)" -ForegroundColor Red
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "修复完成!" -ForegroundColor Green
Write-Host "已修复文件数: $fixedCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "错误数: $errorCount" -ForegroundColor Red
}
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步: 将修改后的文件推送到 GitHub CDN 仓库" -ForegroundColor Yellow
