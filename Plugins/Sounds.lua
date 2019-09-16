--[[  Sounds  ]]--

local Sounds = {}
do
  local _, namespace = ...
  namespace.Sounds = Sounds
end

do
  local Media = LibStub('LibSharedMedia-3.0')
  local PATH = 'Interface\\AddOns\\NetView\\Sounds\\'
  local SOUND
  local soundList = {
    ['Bell'] = PATH..'Bell.ogg',
    ['Chime'] = PATH..'Chime.ogg',
    ['Heart'] = PATH..'Heart.ogg',
    ['IM'] = PATH..'IM.ogg',
    ['Info'] = PATH..'Info.ogg',
    ['Kachink'] = PATH..'Kachink.ogg',
    ['Popup'] = PATH..'Link.ogg',
    ['Text1'] = PATH..'Text1.ogg',
    ['Text2'] = PATH..'Text2.ogg',
    ['Xylo'] = PATH..'Xylo.ogg',
  }
  SOUND = Media.MediaType.SOUND
  for k,v in pairs(soundList) do
    Media:Register(SOUND, k, v)
  end
  soundList = nil

  local play
  function Sounds:PlaySound(sound)
    if (not sound) then return end
    if (play == nil) then
      play = Media:Fetch(SOUND, sound)
    end
    PlaySoundFile(play, 'Master')
  end
end
