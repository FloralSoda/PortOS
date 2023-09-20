local dfpwm = require("cc.audio.dfpwm")

class 'audio' {
    speakers = {},
    playAudio = function(self, lines)
        local speaker = self.device
        if type(lines) == "table" then
            local decoder = dfpwm.make_decoder()
            for chunk in pairs(lines) do
                local buffer = decoder(chunk)

                while not speaker.playAudio(buffer) do
                    os.pullEvent("speaker_audio_empty")
                end
            end
        elseif type(lines) == "string" then
            if fs.exists(lines) then
                local decoder = dfpwm.make_decoder()
                for chunk in io.lines(lines) do
                    local buffer = decoder(chunk)

                    while not speaker.playAudio(buffer) do
                        os.pullEvent("speaker_audio_empty")
                    end
                end
            else
                error("File could not be located", 2)
            end
        else
            error("Argument 2 expected table or filepath, got " .. type(lines), 2)
        end
    end,
    bindSpeaker = function(self, name)
        if type(name) == "string" then
            if not peripheral.isPresent(name) then
                error("Could not find peripheral in network", 2)
            elseif peripheral.getType(name) ~= "speaker" then
                error("The provided peripheral was not a speaker", 2)
            else
                local speakerObject = peripheral.wrap(name)
                local speaker = {
                    device = speakerObject,
                    play = playAudio,
                    id = (os.epoch() + #self.speakers)
                }
                table.insert(self.speakers, speaker)
                return speaker
            end
        elseif type(name) == "table" then
            local success, result = pcall(peripheral.getType, name)
            if success and result == "speaker" then
                local speaker = {
                    device = speakerObject,
                    play = playAudio,
                    id = (os.epoch("utc") + #self.speakers)
                }
                table.insert(audio.speakers, speaker)
                return speaker
            else
                error("Argument was not a speaker", 2)
            end
        else
            error("Argument expected string or peripheral, got " .. type(name), 2)
        end
    end,
    unbindSpeaker = function(self, speaker)
        local toRemove = -1
        for idx, s in pairs(self.speakers) do
            if s.id == speaker.id then
                toRemove = idx
                break
            end
        end

        table.remove(self.speakers, toRemove)
    end
}

return audio
