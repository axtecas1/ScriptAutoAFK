script_name("Auto AFK OCR V10 (Toggle ModoAFK)")
local samp = require 'lib.samp.events'
local os = require 'os'
local ffi = require 'ffi'

-- Carrega a funcao do Windows para procurar janelas
ffi.cdef[[
    int FindWindowA(const char* lpClassName, const char* lpWindowName);
]]

local idTextDrawAfk = -1
local loopAtivo = false
local ultimoAvisoErro = 0

-- Funcao que checa se o executavel da IA esta rodando
local function isLeitorAberto()
    local hwnd = ffi.C.FindWindowA(nil, "LEITOR_IA_AFK")
    return hwnd ~= 0
end

-- Funcao para abrir o executavel automaticamente
local function abrirLeitor()
    if not isLeitorAberto() then
        os.execute('start /b leitor.exe')
        return true
    end
    return false
end

local function iniciarProcessoAfk()
    if loopAtivo then return end
    loopAtivo = true
    
    sampAddChatMessage("{00FF00}[Auto-AFK]{FFFFFF} Sistema identificado: Voce esta AFK.", -1)
    
    -- SINAL DE PAUSA: Avisa aos outros scripts para pararem agora
    sampAddChatMessage("{00FF00}[Auto-AFK]{FFFFFF} Desativando scripts de automacao (/modoafk).", -1)
    sampSendChat("/modoafk")
    
    lua_thread.create(function()
        while idTextDrawAfk ~= -1 do
            local f = io.open("afk_trigger.txt", "w")
            if f then
                f:write("ler")
                f:close()
                sampAddChatMessage("{00FF00}[Auto-AFK]{FFFFFF} IA esta processando o codigo, aguarde...", -1)
            end
            
            local tempo = 0
            while tempo < 40 and idTextDrawAfk ~= -1 do
                wait(1000)
                tempo = tempo + 1
                
                local res = io.open("afk_codigo.txt", "r")
                if res then
                    local conteudo = res:read("*a")
                    res:close()
                    os.remove("afk_codigo.txt")
                    os.remove("afk_trigger.txt")
                    
                    local numeros = conteudo:match("%d%d%d%d")
                    if numeros then
                        sampAddChatMessage("{00FF00}[Auto-AFK]{FFFFFF} IA concluiu a leitura: {FFFF00}" .. numeros, -1)
                        wait(2000) -- Delay de seguranca
                        if idTextDrawAfk ~= -1 then
                            sampSendChat("/sairafk " .. numeros)
                        end
                        break
                    end
                end
            end
        end
        loopAtivo = false
    end)
end

-- DETECCAO DE FIM DO MODO AFK VIA CHAT (RETOMADA)
function samp.onServerMessage(color, text)
    local cleanText = text:gsub("{%x%x%x%x%x%x}", "")
    -- Verifica a mensagem de desbloqueio do servidor
    if cleanText:find("ANTI%-AFK") and cleanText:find("desbloqueado de upar") then
        sampAddChatMessage("{00FF00}[Auto-AFK]{FFFFFF} Detectado fim do AFK. Reativando scripts (/modoafk).", -1)
        -- SINAL DE RETOMADA: Avisa aos scripts pausados para voltarem
        sampSendChat("/modoafk")
    end
end

function samp.onShowTextDraw(id, data)
    local texto = data.text:gsub("~.-~", "")
    if texto:lower():find("voce esta ausente") then
        if not isLeitorAberto() then
            sampAddChatMessage("{FF0000}[ERRO] O sistema de IA (leitor.exe) nao foi encontrado!", -1)
        else
            idTextDrawAfk = id
            iniciarProcessoAfk()
        end
    end
end

function samp.onRemoveTextDraw(id)
    if id == idTextDrawAfk then
        idTextDrawAfk = -1
        os.remove("afk_trigger.txt")
        os.remove("afk_codigo.txt")
        sampAddChatMessage("{00FF00}[Auto-AFK]{FFFFFF} AFK resolvido. Sistema em espera.", -1)
    end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    -- Banner de Inicio
    sampAddChatMessage("{00FF00}Sistema AutoAFK V.1.5.R", -1)
    sampAddChatMessage("{00FF00}Desenvolvido por: Axtecas", -1)
    sampAddChatMessage("{00FF00}Ativado automaticamente ao logar.", -1)
    
    wait(1000)
    abrirLeitor()
    
    while true do
        wait(1000)
        -- Busca continua por TextDraws
        if idTextDrawAfk == -1 then
            for i = 0, 2304 do
                if sampTextdrawIsExists(i) then
                    local texto = sampTextdrawGetString(i)
                    if texto and texto:gsub("~.-~", ""):lower():find("voce esta ausente") then
                        if isLeitorAberto() then
                            idTextDrawAfk = i
                            iniciarProcessoAfk()
                            break
                        end
                    end
                end
            end
        end
    end
end