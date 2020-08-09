--[[
Copyright (c) 2014-2020 Iruatã M.S. Souza <iru.muzgo@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the Author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
]]

local data = require'data'
local np = require'9p'
local socket = require 'socket'
local pprint = require 'pprint'

local ORDONLY = 0
local OWRITE = 1
local ORDWR = 2
local OEXEC = 3 

local READ_BUF_SIZ = 4096

function _9p_readdir(ctx, path) 
  local f = ctx:newfid()
  local offset = 0
  local dir, data = nil, nil

  ctx:walk(ctx.rootfid, f, path) 
  ctx:open(f, ORDONLY)  

  data = ctx:read(f, offset, READ_BUF_SIZ) 
  dir = tostring(data)
  pprint(data)
  offset = offset + #data

  while (true) do
    data = ctx:read(f, offset, READ_BUF_SIZ)

    if (data == nil) then
      break
    end
    dir = dir .. tostring(data)
    offset = offset + #(tostring(data))
  end

  print("Read " .. #dir .. " bytes")
  ctx:clunk(f)
  return dir
end

function readdir(ctx, path) 
  local dir = {}
  local dirdata = _9p_readdir(ctx, path)
  while 1 do
    st = ctx:getstat(data.new(dirdata))   
    table.insert(dir, st)
    dirdata = string.sub(dirdata, st.size + 3) 
    if (#dirdata == 0) then
      break
    end
  end
  return dir
end

local tcp = socket:tcp()

local connection, err = tcp:connect("127.0.0.1", 3333)

if (err ~= nil) then
  error("Connection error")
end

local conn = np.attach(tcp, "bebebeko", "")

for n, file in pairs(readdir(conn, "/tmp")) do
  print(file.name)
end

for n, file in pairs(readdir(conn, "/chan")) do
  print(file.name)
end
