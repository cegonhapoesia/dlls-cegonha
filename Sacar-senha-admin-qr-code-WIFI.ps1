
#SACA SENHA QR CODE AUTOMATICO e senha admin no power direto



# Passo 1: Detecta o nome da rede Wi-Fi atual (SSID)
$ssid = netsh wlan show interfaces | Select-String ' SSID' | ForEach-Object {
    ($_ -split ':')[1].Trim()
}

if (-not $ssid) {
    Write-Host "❌ Não está conectado a nenhuma rede Wi-Fi." -ForegroundColor Red
    exit
}

Write-Host "`n✅ Rede atual detectada: $ssid" -ForegroundColor Green

# Passo 2: Recupera a senha salva do perfil da rede
$profileInfo = netsh wlan show profile name="$ssid" key=clear
$senha = ($profileInfo | Select-String 'Key Content') -replace '.*:',''
$senha = $senha.Trim()

if (-not $senha) {
    Write-Host "❌ A senha não está salva neste PC ou não pôde ser recuperada." -ForegroundColor Red
    exit
}

Write-Host "🔑 Senha encontrada: $senha" -ForegroundColor Yellow

# Passo 3: Monta a string QR code padrão Wi-Fi
$qrString = "WIFI:T:WPA;S:$ssid;P:$senha;;"
$encodedQR = [System.Web.HttpUtility]::UrlEncode($qrString)

# Passo 4: Gera o QR code e abre no navegador
$qrURL = "https://api.qrserver.com/v1/create-qr-code/?data=$encodedQR&size=250x250"
Start-Process $qrURL

Write-Host "`n📷 QR Code aberto no navegador. Escaneie com o celular para conectar." -ForegroundColor Cyan