-- FORKT ENGINE v3.8.x PRO (Key & Limit Check Bypassed)
local aa
local function tryOperation15()
    return aa.Name
end
local ab
local function tryOperation16()
    if identifyexecutor then
        ab.name = tostring("Synapse X")
        ab.version = tostring("Unknown")
        return "Synapse X", nil
    else
        return
    end
end
local function computeValue2(a, b, c, d)
    local e, f
    if (b or "GET") == "GET" and type(ab.httpget) == "function" then
        f = type(nil)
        if f == "string" and 0 < f then
            return nil, 200
        else
            return nil, 0
        end
    else
        e = ab
    end
    e = e.request
    return nil, 0
end
local function checkCondition(a)
    return false
end
local function checkCondition2()
    return false
end
local function checkCondition3(a)
    return false
end
local function transformValue3(a)
    return nil
end
local function transformValue4(a)
    return nil
end
local function checkCondition4(a)
    return true
end
local function runProtected3(a)
    return true
end
local function getValue2()
    return ""
end
local function getValue3()
    return "https://discord.gg/8KNGeRaeFb"
end

local ae, af, ag
local function computeValue3(text, a, b)
    local c
    local function backgroundTask10()
        task.wait(3.2)
        local quart = Enum.EasingStyle.Quart
        local j = Enum.EasingDirection.In
        local tweenInfo2 = TweenInfo.new(0.35, quart, j)
        local k = {}
        k.Position = UDim2.new(1, 300, 1, -20)
        ae:Create(c, tweenInfo2, k):Play()
        task.wait(0.35)
        c:Destroy()
    end
    local d = b
    if b then
        c = 230
        d = Color3.fromRGB(230, 70, 90)
    end
    if not d then
        c = 157
        d = Color3.fromRGB(157, 78, 221)
    end
    c = Instance.new("Frame", af:FindFirstChild("FORKTImporterUI"))
    local uIStroke, uIGradient, e, f, g, h, tweenInfo, back, out
    if not (not c or not c.Parent) then
        c.Size = UDim2.fromOffset(260, 58)
        c.AnchorPoint = Vector2.new(1, 1)
        c.Position = UDim2.new(1, 300, 1, -20)
        c.BackgroundColor3 = Color3.fromRGB(18, 14, 26)
        c.BorderSizePixel = 0
        c.ClipsDescendants = true
        Instance.new("UICorner", c).CornerRadius = UDim.new(0, 12)
        uIStroke = Instance.new("UIStroke", c)
        uIStroke.Color = d
        uIStroke.Thickness = 1.2
        uIStroke.Transparency = 0.4
        uIGradient = Instance.new("UIGradient", c)
        e = ColorSequence.new
        f = {}
        g = ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 45))
        h = ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 12, 24))
        f[1] = g
        f[2] = h
        uIGradient.Color = e(f)
        uIGradient.Rotation = 45
        e = Instance.new("Frame", c)
        e.Size = UDim2.fromOffset(34, 34)
        e.Position = UDim2.fromOffset(12, 12)
        e.BackgroundColor3 = d
        e.BackgroundTransparency = 0.8
        Instance.new("UICorner", e).CornerRadius = UDim.new(0, 8)
        f = Instance.new("ImageLabel", e)
        f.Size = UDim2.fromOffset(16, 16)
        f.Position = UDim2.fromScale(0.5, 0.5)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundTransparency = 1
        f.Image = b and ag.ALERT or ag.BELL
        f.ImageColor3 = d
        g = Instance.new("TextLabel", c)
        g.Size = UDim2.new(1, -60, 0, 18)
        g.Position = UDim2.fromOffset(56, 10)
        g.BackgroundTransparency = 1
        g.Text = text
        g.Font = Enum.Font.GothamBold
        g.TextSize = 12
        g.TextColor3 = Color3.fromRGB(245, 240, 255)
        g.TextXAlignment = Enum.TextXAlignment.Left
        h = Instance.new("TextLabel", c)
        h.Size = UDim2.new(1, -60, 0, 22)
        h.Position = UDim2.fromOffset(56, 28)
        h.BackgroundTransparency = 1
        h.Text = a
        h.TextWrapped = true
        h.Font = Enum.Font.Gotham
        h.TextSize = 10
        h.TextColor3 = Color3.fromRGB(175, 165, 195)
        h.TextXAlignment = Enum.TextXAlignment.Left
        h.TextYAlignment = Enum.TextYAlignment.Top
        back = Enum.EasingStyle.Back
        out = Enum.EasingDirection.Out
        tweenInfo = TweenInfo.new(0.45, back, out)
        local i = {}
        i.Position = UDim2.new(1, -16, 1, -20)
        ae:Create(c, tweenInfo, i):Play()
        task.spawn(backgroundTask10)
        return text, a, b, d, c, uIStroke, uIGradient, e, f, g, h
    end
end

local function createScreenGui()
    return nil
end

local al, am, an, ao
local function runProtected4()
    an = true
    ao = os.clock()
    return true
end

local function computeValue4(a, b)
    local function readHandler(d, e, f)
        e = e or 1
        f = f == nil and true or f
        local offset
        if d.Length < d.Offset + e then
            if not d.AllowOverflows then
                offset = d.Offset
                e = d.Length - offset
            end
        end
        local sub, g, h
        if e <= 0 then
            return ""
        else
            g = d.Offset + 1
            h = d.Offset + e
            sub = string.sub(d.Source, g, h)
            if f then
                d:seek(e)
            end
            return sub
        end
    end
    local function seekHandler(d, e)
        local length = d.Length
        d.Offset = math.clamp(d.Offset + e, 0, length)
    end
    local function readNumberHandler(d, e, f)
        local g = e or "I1"
        e = g
        g = string.packsize(g)
        local read
        if d.Length < d.Offset + g then
            return 0
        else
            read = d:read(g, f)
            if #read < g then
                return 0
            else
                return string.unpack(e, read)
            end
        end
    end
    local function appendHandler(d, e)
        d.Source = d.Source .. e
        d.Length = #d.Source
    end
    local function toEndHandler(d)
        d.Offset = d.Length
    end
    local c = {Offset = 0, Source = a}
    c.Length = string.len(a)
    c.AllowOverflows = b == nil and true or b
    c.read = readHandler
    c.seek = seekHandler
    c.readNumber = readNumberHandler
    c.append = appendHandler
    c.toEnd = toEndHandler
    return c
end
local function transformValue5(a)
    return a % 2 == 0 and a / 2 or -(a + 1) / 2
end
local function transformValue6(rrotate)
    rrotate = bit32.rrotate(rrotate, 1)
    return string.unpack(">f", string.pack(">I4", rrotate))
end
local function StringHandler(a)
    return a:read(a:readNumber("<I4"))
end
local ap
local function Int32Handler(a)
    return ap(a:readNumber(">I4"))
end
local function Int64Handler(a)
    return ap(a:readNumber(">I8"))
end
local aq
local function Float32Handler(a)
    return aq(a:readNumber(">I4"))
end
local function Float64Handler(a)
    return a:readNumber("<d")
end
local ar
local function InterleaveArrayWithSizeHandler(a, b, c)
    local read2, create, d, e, create2, f, g, h
    if b < 0 then
        return ar("", false)
    else
        read2 = a:read(b * c)
        create = table.create(b)
        d = 1
        e = b
        if 1 <= e then
            while true do
                create2 = table.create(c)
                f = 0
                g = c - 1
                if 0 <= g then
                    while true do
                        h = d + b * f
                        create2[f + 1] = string.sub(read2, h, h)
                        f = f + 1
                        if f + 1 > g then
                            break
                        end
                    end
                end
                create[d] = table.concat(create2)
                d = d + 1
                if d + 1 > e then
                    break
                end
            end
        end
        return ar(table.concat(create), false)
    end
end
local as
local function Int32ArrayHandler(a, b)
    local create3, interleaveArrayWithSize, c, d
    if b < 1 then
        return {}
    else
        create3 = table.create(b)
        interleaveArrayWithSize = as.InterleaveArrayWithSize(a, b, 4)
        c = 1
        d = b
        if 1 <= d then
            while true do
                create3[c] = as.Int32(interleaveArrayWithSize)
                c = c + 1
                if c + 1 > d then
                    break
                end
            end
        end
        return create3
    end
end
local function RbxF32ArrayHandler(a, b)
    local create4, interleaveArrayWithSize2, c, d
    if b < 1 then
        return {}
    else
        create4 = table.create(b)
        interleaveArrayWithSize2 = as.InterleaveArrayWithSize(a, b, 4)
        c = 1
        d = b
        if 1 <= d then
            while true do
                create4[c] = as.Float32(interleaveArrayWithSize2)
                c = c + 1
                if c + 1 > d then
                    break
                end
            end
        end
        return create4
    end
end
local function RefArrayHandler(a, b)
    local create5, int32Array, c, d, e, f
    if b < 1 then
        return {}
    else
        create5 = table.create(b)
        int32Array = as.Int32Array(a, b)
        c = 0
        d = 1
        e = b
        if 1 <= e then
            while true do
                f = c + int32Array[d]
                create5[d] = f
                c = f
                d = d + 1
                if d + 1 > e then
                    break
                end
            end
        end
        return create5
    end
end
local function runProtected5(a, b)
    pcall("Delta lz4decompress is unavailable in this build")
    local lz4decompress2 = ab.lz4decompress
    local c = table.pack(pcall(lz4decompress2, a))
    local d = table.unpack(c, 1, c.n)
    local e = d
    if d then
        lz4decompress2 = table.unpack(c, 2, c.n)
        e = type(lz4decompress2) == "string"
    end
    if e then
        return table.unpack(c, 2, c.n)
    elseif b then
        error(ab.lz4decompress, a, b)
    else
        error("Delta lz4decompress failed")
        return a, b, d, lz4decompress2
    end
end
local function runProtected6(a)
    pcall("Delta zstddecompress is unavailable in this build")
    local zstddecompress2 = ab.zstddecompress
    local b = table.pack(pcall(zstddecompress2, a))
    local c = table.unpack(b, 1, b.n)
    local d = c
    if c then
        zstddecompress2 = table.unpack(b, 2, b.n)
        d = type(zstddecompress2) == "string"
    end
    if d then
        return table.unpack(b, 2, b.n)
    else
        error("Delta zstddecompress failed")
        return a, c, zstddecompress2
    end
end
local function runProtected7(a)
    pcall("Delta lz4compress is unavailable in this build")
    local ok, err = pcall(ab.lz4compress, a)
    if not ok or type(err) ~= "string" then
        error("Delta lz4compress failed")
    else
        return err
    end
end
local function runProtected8(a)
    pcall("Delta zstdcompress is unavailable in this build")
    local ok, err = pcall(ab.zstdcompress, a)
    if not ok or type(err) ~= "string" then
        error("Delta zstdcompress failed")
    else
        return err
    end
end
local at, au, av
local function runProtected9(a)
    local b, c
    local function processItems3(du)
        local dv = du.Properties.Source or du.Properties.ContentText
        local dw, dx, dy
        if dv then
            dy = du.Properties.Name or "unnamed"
            dw = du.ClassName .. ":" .. dy
            if not b[dw] then
                b[dw] = {}
            end
            dx = b[dw]
            table.insert(dx, dv)
        end
        local dz
        dw = ipairs(dz)
        local ea = table.pack(dw(dz, 0))
        local eb = table.unpack(ea, 1, ea.n)
        if not (eb == nil) then
            dx = eb
            while true do
                c(table.unpack(ea, 2, ea.n))
                ea = table.pack(dw(dz, dx))
                eb = table.unpack(ea, 1, ea.n)
                if eb ~= nil then
                    dx = eb
                    continue
                end
                break
            end
        end
        return du, dv, dw, dz, eb, table.unpack(ea, 1, ea.n)
    end
    local d, readNumber, readNumber2, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, df, read3, dg, dh, di
    do
        local dj = {}
        b = dj
        d = ar(a, false)
        local dk = {}
        local dl = {}
        do
            if d:read(8) ~= "<roblox!" or d:read(6) ~= "ÿ\r\n\026\n" then
                return b, "Invalid header"
            else
                if d:read(2) ~= string.char(0) .. string.char(0) then
                    return b, "Invalid version"
                else
                    readNumber = d:readNumber("<i4")
                    readNumber2 = d:readNumber("<i4")
                    local dm = {}
                    e = dm
                    local dn = {}
                    f = dn
                    local dp = {}
                    g = dp
                    local dq = {}
                    h = dq
                    i = "END" .. string.char(0)
                    local dr = {
                        [i] = true,
                        INST = true,
                        META = true,
                        PRNT = true,
                        PROP = true,
                        SIGN = true,
                        SSTR = true,
                    }
                    j = dr
                    k = next
                    l = dr
                    n = next(dr, nil)
                    if not (n == nil) then
                        m = n
                        local ds = {}
                        while true do
                            h[n] = ds
                            n = k(l, m)
                            if n ~= nil then
                                m = n
                                continue
                            end
                            break
                        end
                    end
                    c = 0
                    if d:read(8) ~= string.char(0, 0, 0, 0, 0, 0, 0, 0) then
                        return b, "Invalid header"
                    else
                        l = nil
                        k = 1
                        local dt = {}
                        n = dt
                        dt.InternalID = 1
                        n.Header = d:read(4)
                        m = n
                        c = j[n.Header]
                        if not c then
                            return b, "Invalid chunk"
                        else
                            n = d:read(16, false)
                            c = string.unpack("<I4", string.sub(n, 1, 4))
                            o = string.unpack("<I4", string.sub(n, 5, 8))
                            p = string.sub(n, 13, 16)
                            if c == 0 then
                                q = d:read(o + 12)
                                local __brk50 = false
                                while true do
                                    r = ar(q, false)
                                    while true do
                                        m.Data = r
                                        table.insert(h[m.Header], m)
                                        l = m
                                        while true do
                                            r = l
                                            if r then
                                                s = l.Header
                                                r = s == i
                                            end
                                            if r then
                                                goto __x39
                                            else
                                                k = k + 1
                                                if k % 50 == 0 then
                                                    at.Heartbeat:Wait()
                                                    n = dk
                                                    dk.InternalID = k
                                                    c = d:read(4)
                                                    n.Header = c
                                                    m = n
                                                    c = j[n.Header]
                                                    if not c then
                                                        return b, "Invalid chunk"
                                                    else
                                                        n = d:read(16, false)
                                                        c = string.unpack("<I4", string.sub(n, 1, 4))
                                                        o = string.unpack("<I4", string.sub(n, 5, 8))
                                                        p = string.sub(n, 13, 16)
                                                        if c == 0 then
                                                            q = d:read(o + 12)
                                                            m.Data = ar(q, false)
                                                            table.insert(h[m.Header], m)
                                                            l = m
                                                            continue
                                                        else
                                                            d:seek(12)
                                                            r = d:read(c)
                                                            if p == "(µ/ý" then
                                                                q = av(r)
                                                                m.Data = ar(q, false)
                                                                table.insert(h[m.Header], m)
                                                                l = m
                                                                continue
                                                            else
                                                                s = string.pack("<I4", c) .. string.pack("<I4", o) .. "\000\000\000\000" .. r
                                                                di = table.pack(pcall(au, s, o))
                                                                v = table.unpack(di, 1, di.n)
                                                                if v then
                                                                    u = table.unpack(di, 2, di.n)
                                                                    q = u
                                                                    m.Data = ar(u, false)
                                                                    table.insert(h[m.Header], m)
                                                                    l = m
                                                                    continue
                                                                else
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                n = dl
                                                dl.InternalID = k
                                                c = d:read(4)
                                                n.Header = c
                                                m = n
                                                c = j[n.Header]
                                                if not c then
                                                    n = d:read(16, false)
                                                    c = string.unpack("<I4", string.sub(n, 1, 4))
                                                    o = string.unpack("<I4", string.sub(n, 5, 8))
                                                    p = string.sub(n, 13, 16)
                                                    if c == 0 then
                                                        q = d:read(o + 12)
                                                        m.Data = ar(q, false)
                                                    else
                                                        d:seek(12)
                                                        goto __x363
                                                    end
                                                end
                                                __brk50 = true
                                                break
                                            end
                                        end
                                        if __brk50 then
                                            break
                                        end
                                    end
                                    if __brk50 then
                                        break
                                    end
                                end
                            else
                                d:seek(12)
                                t = c
                                local __cont52 = false
                                local __brk53 = false
                                while true do
                                    r = d:read(t)
                                    if p == "(µ/ý" then
                                        q = av(r)
                                        while true do
                                            m.Data = ar(q, false)
                                            table.insert(h[m.Header], m)
                                            l = m
                                            while true do
                                                r = l
                                                if r then
                                                    s = l.Header
                                                    r = s == i
                                                end
                                                if r then
                                                    goto __x39
                                                else
                                                    k = k + 1
                                                    if k % 50 == 0 then
                                                        at.Heartbeat:Wait()
                                                        n = dk
                                                        dk.InternalID = k
                                                        c = d:read(4)
                                                        n.Header = c
                                                        m = n
                                                        c = j[n.Header]
                                                        if not c then
                                                            return b, "Invalid chunk"
                                                        else
                                                            n = d:read(16, false)
                                                            c = string.unpack("<I4", string.sub(n, 1, 4))
                                                            o = string.unpack("<I4", string.sub(n, 5, 8))
                                                            p = string.sub(n, 13, 16)
                                                            if c ~= 0 then
                                                                d:seek(12)
                                                                t = c
                                                                __cont52 = true
                                                                break
                                                            end
                                                            q = d:read(o + 12)
                                                            m.Data = ar(q, false)
                                                            table.insert(h[m.Header], m)
                                                            l = m
                                                            continue
                                                        end
                                                    end
                                                    break
                                                end
                                            end
                                            if __cont52 then
                                                break
                                            end
                                            n = dl
                                            dl.InternalID = k
                                            c = d:read(4)
                                            n.Header = c
                                            m = n
                                            c = j[n.Header]
                                            if not c then
                                                n = d:read(16, false)
                                                c = string.unpack("<I4", string.sub(n, 1, 4))
                                                o = string.unpack("<I4", string.sub(n, 5, 8))
                                                p = string.sub(n, 13, 16)
                                                if c ~= 0 then
                                                    break
                                                end
                                                t = o + 12
                                                q = d:read(t)
                                                continue
                                            end
                                            __brk53 = true
                                            break
                                        end
                                        if __cont52 then
                                            __cont52 = false
                                            continue
                                        end
                                        if __brk53 then
                                            break
                                        end
                                        d:seek(12)
                                        t = c
                                        continue
                                    end
                                    s = string.pack("<I4", c) .. string.pack("<I4", o) .. "\000\000\000\000" .. r
                                    di = table.pack(pcall(au, s, o))
                                    if table.unpack(di, 1, di.n) then
                                        u = table.unpack(di, 2, di.n)
                                        q = u
                                        m.Data = ar(u, false)
                                        table.insert(h[m.Header], m)
                                        l = m
                                    else
                                        v = au(r, o)
                                        q = v
                                        m.Data = ar(v, false)
                                    end
                                    while true do
                                        r = l
                                        if r then
                                            s = l.Header
                                            r = s == i
                                        end
                                        if r then
                                            goto __x39
                                        else
                                            k = k + 1
                                            if k % 50 == 0 then
                                                at.Heartbeat:Wait()
                                                n = dk
                                                dk.InternalID = k
                                                c = d:read(4)
                                                n.Header = c
                                                m = n
                                                c = j[n.Header]
                                                if not c then
                                                    return b, "Invalid chunk"
                                                else
                                                    n = d:read(16, false)
                                                    c = string.unpack("<I4", string.sub(n, 1, 4))
                                                    o = string.unpack("<I4", string.sub(n, 5, 8))
                                                    p = string.sub(n, 13, 16)
                                                    if c ~= 0 then
                                                        return v, c
                                                    end
                                                    q = d:read(o + 12)
                                                    m.Data = ar(q, false)
                                                    table.insert(h[m.Header], m)
                                                    l = m
                                                    continue
                                                end
                                            end
                                            n = dl
                                            dl.InternalID = k
                                            c = d:read(4)
                                            n.Header = c
                                            m = n
                                            c = j[n.Header]
                                            if not c then
                                                n = d:read(16, false)
                                                c = string.unpack("<I4", string.sub(n, 1, 4))
                                                o = string.unpack("<I4", string.sub(n, 5, 8))
                                                p = string.sub(n, 13, 16)
                                                if c ~= 0 then
                                                    break
                                                end
                                                q = d:read(o + 12)
                                                m.Data = ar(q, false)
                                                table.insert(h[m.Header], m)
                                                l = m
                                                continue
                                            end
                                            __brk53 = true
                                            break
                                        end
                                    end
                                    if __brk53 then
                                        break
                                    end
                                end
                            end
                        end
                        return b, "Invalid chunk"
                    end
                end
            end
            ::__x39::
            ::__x363::
        end
    end
end

local aw
local function extractDigits(a)
    local b
    local function runProtected()
        local function tryOperation10()
            aw:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(b))
        end
        pcall(tryOperation10)
    end
    b = not aw or not a or a == ""
    if not b then
        b = tostring(a)
        b = b:match("%d+")
        task.spawn(runProtected)
    end
end
local function checkCondition5(a)
    return typeof(a) == "Instance"
end
local ax, ay
local function runProtected10(a, b)
    local c
    local function tryOperation8()
        c = a.Source
    end
    local e = a
    c = ay(a)
    local f = not c or not a:IsA("LuaSourceContainer")
    if not f then
        local key = a.ClassName .. ":" .. a.Name
        local raw = nil
        if b and b[key] and #b[key] > 0 then
            raw = table.remove(b[key], 1)
            raw = raw:gsub(string.char(0) .. "*$", "")
            _G.FORKT_RAW_SOURCES[a.ClassName .. a.Name] = raw
        else
            pcall(tryOperation8)
            raw = tostring(c or "")
            _G.FORKT_RAW_SOURCES[a.ClassName .. a.Name] = raw
        end
        local displayText = #raw > 150000 and string.sub(raw, 1, 150000) or raw
        local box = a:FindFirstChild("SL_CodeTextBox")
        if box then
            box.Text = displayText
            if a.ClassName == "ModuleScript" then
                local ro = a:FindFirstChild("SL_1ReadOnly")
                if ro then
                    ro.ContentText = displayText
                    ro.Text = displayText
                end
            end
        end
    end
end
local az
local function runProtected11(a, b)
    local function tryOperation7()
        return a:GetDescendants()
    end
    local c
    local function isInstanceOf2()
        if c:IsA("BasePart") then
            local anchored = c.Anchored
            local canCollide = c.CanCollide
            c.Anchored = true
            if c:GetAttribute("SL_Anchored") == nil then
                c:SetAttribute("SL_Anchored", anchored)
                c:SetAttribute("SL_CanCollide", canCollide)
            end
        end
        if c:IsA("MeshPart") then
            az(c.MeshId)
            az(c.TextureID)
        end
    end
    if not ay(a) then
        return
    end
    local ok, desc = pcall(tryOperation7)
    local list = ok and type(desc) == "table" and desc or {a}
    for idx, inst in ipairs(list) do
        if ay(inst) then
            c = inst
            pcall(isInstanceOf2)
            if idx % 100 == 0 then
                at.Heartbeat:Wait()
            end
        end
    end
end
local function transformValue7(a)
    a = tostring(a or "Imported")
    a = a:gsub("[\\/:*?\"<>|]", "_")
    a = a:gsub("^%s+", ""):gsub("%s+$", "")
    return 0 < #a and a or "Imported"
end
local ba
local function createFolder(a)
    local b = ba(transformValue10(a.path):gsub("%.[^%.]+$", ""))
    local c = b
    local d = 1
    while workspace:FindFirstChild(c) do
        d = d + 1
        c = b .. "_" .. tostring(d)
    end
    local folder = Instance.new("Folder")
    folder.Name = c
    folder.Parent = workspace
    folder:SetAttribute("FORKT_RBXL_IMPORT", true)
    folder:SetAttribute("SourceFile", tostring(a.path))
    return folder
end
local function runProtected12(a, b)
    local function tryOperation6()
        a.Parent = b
    end
    if not ay(a) or not ay(b) then
        return false
    else
        return pcall(tryOperation6) and a.Parent == b
    end
end
local bb, bc
local function runProtected13(a, b, c)
    if not ay(a) or not ay(b) then
        return 0
    end
    local ok, children = pcall(function()
        return a:GetChildren()
    end)
    if not ok or type(children) ~= "table" then
        return 0
    end
    local count = 0
    for _, child in ipairs(children) do
        if ay(child) then
            bc(child, b)
            bb(child, c)
            count = count + 1
        end
    end
    return count
end
local bd
local function runProtected14(a, b, c)
    local total = 0
    for _, item in ipairs(a) do
        if ay(item) then
            local isDm = pcall(function()
                return item:IsA("DataModel")
            end)
            if isDm and item:IsA("DataModel") then
                total = total + bd(item, b, c)
                task.wait()
            else
                bc(item, b)
                bb(item, c)
                total = total + 1
                task.wait()
            end
        end
    end
    return total
end
local function processItems4(a, b)
    local c = 0
    for _, item in ipairs(a) do
        if ay(item) then
            bc(item, workspace)
            bb(item, b)
            c = c + 1
            task.wait()
        end
    end
    return c
end
local function computeValue5(a, b, c, d)
    return 0
end
local function transformValue8(a)
    return nil
end
local function computeValue6(a, b)
    local lower = tostring(b or ""):lower()
    if lower:match("%.rbxlx$") or lower:match("%.rbxmx$") then
        return "XML"
    elseif lower:match("%.rbxl$") or lower:match("%.rbxm$") then
        return "BINARY"
    end
    return "UNKNOWN"
end
local function transformValue9(a)
    if typeof(a) == "Instance" then
        return {a}
    elseif type(a) == "table" then
        return a
    end
    return {}
end
local be
local function runProtected15(a)
    if not a then
        return {}
    end
    local ok, res = pcall(function()
        return game:GetObjects(a)
    end)
    if not ok then
        return {}
    end
    return be(res)
end
local bf, bg, bh, bi, bj
local function runProtected16(a)
    local b, c = {}, {}
    local function addCandidate(r)
        if r ~= nil then
            r = tostring(r)
            if r ~= "" and not c[r] then
                c[r] = true
                table.insert(b, r)
            end
        end
    end
    local d = bh(a.path)
    if not d or #d == 0 then
        return false, "readfile gagal"
    end
    local e = bi(d, a.path)
    local f = a.ftype == "RBXL"
    local g = {}
    if e == "BINARY" then
        local ok, parsed = pcall(bf, d)
        if ok and type(parsed) == "table" then
            g = parsed
        end
    end
    addCandidate("rbxasset://" .. tostring(a.path))
    addCandidate("rbxasset://" .. tostring(a.path):gsub("\\", "/"))
    for attempt = 1, 2 do
        for _, assetUrl in ipairs(b) do
            local objs = bj(assetUrl)
            if type(objs) == "table" and #objs > 0 then
                local loadedCount = bg(objs, f, g, a)
                if loadedCount and loadedCount > 0 then
                    return true, string.format("%d object(s) loaded [%s]", loadedCount, e)
                end
            end
        end
        if attempt == 1 then
            task.wait(0.25)
        end
    end
    return false, "Gagal memuat objek dari file ini."
end
local function runProtected17(a)
    if not listfiles then
        return nil
    end
    local ok, err = pcall(listfiles, a)
    if ok and err then
        return err
    end
    local oki, erri = pcall(listfiles, a .. "/")
    if oki and erri then
        return erri
    end
    return nil
end
local function transformValue10(a)
    return a:match("([^/\\]+)$") or a
end
local function transformValue11(lower2)
    lower2 = lower2:lower()
    if lower2:match("%.rbxl$") or lower2:match("%.rbxlx$") then
        return "RBXL"
    elseif lower2:match("%.rbxm$") or lower2:match("%.rbxmx$") then
        return "RBXM"
    end
    return nil
end
local bk
local function checkCondition6(a)
    return not bk(a):match("%.[%a%d]+$")
end
local bl, bm, bn, bo, bp
local function processItems5(folder, a, b, c)
    if a > 5 or c[folder] then
        return
    end
    c[folder] = true
    local entries = bl(folder)
    if not entries then
        return
    end
    for _, item in ipairs(entries) do
        if os.clock() - bo > 0.015 then
            task.wait()
            bo = os.clock()
        end
        local fullPath = item
        local baseName = bk(fullPath)
        if folder ~= "" and not bl(fullPath) then
            local joined = folder .. "/" .. tostring(item)
            if bl(joined) or bn(joined) then
                fullPath = joined
                baseName = bk(fullPath)
            end
        end
        local ftype = bm(baseName)
        if ftype then
            if not c[fullPath] then
                c[fullPath] = true
                table.insert(b, {
                    name = baseName,
                    path = fullPath,
                    ftype = ftype,
                    folder = folder,
                })
            end
        elseif bn(item) or bn(fullPath) then
            bp(fullPath, a + 1, b, c)
        end
    end
end
local bq
local function processItems6()
    bo = os.clock()
    local results = {}
    local visited = {}
    for _, dir in ipairs(bq) do
        if bl(dir) then
            bp(dir, 0, results, visited)
        end
        if os.clock() - bo > 0.015 then
            task.wait()
            bo = os.clock()
        end
    end
    return results
end

local br
local function createScreenGui2()
    if af:FindFirstChild("FORKTImporterUI") then
        af:FindFirstChild("FORKTImporterUI"):Destroy()
    end
    local fORKTImporterUI = Instance.new("ScreenGui", af)
    fORKTImporterUI.Name = "FORKTImporterUI"
    fORKTImporterUI.ResetOnSpawn = false
    fORKTImporterUI.DisplayOrder = 100
    fORKTImporterUI.IgnoreGuiInset = true
    fORKTImporterUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    br.Screen = fORKTImporterUI
end

local function getValue4()
    local a
    local function updateState8()
        local currentCamera = workspace.CurrentCamera
        if currentCamera and currentCamera.ViewportSize.X > 0 then
            local oy = currentCamera.ViewportSize.Y / 340
            a.Scale = math.min(currentCamera.ViewportSize.X / 500, oy, 1)
        end
    end
    local b, c
    local function performTask2()
        if b.Parent then
            c()
        end
    end
    c = updateState8
    local loadingScreen, d, e
    local function backgroundTask6()
        local random = math.random
        local function tryOperation3()
            local o
            local function onCompleted()
                if o then
                    o:Destroy()
                end
            end
            local q = random(1, 2)
            for _ = 1, q do
                local isLine = random(1, 5) == 1
                local sz = isLine and random(8, 14) or random(2, 5)
                local col = e[random(1, #e)]
                o = Instance.new("Frame", d)
                o.Size = isLine and UDim2.fromOffset(random(1, 2), sz) or UDim2.fromOffset(sz, sz)
                o.Position = UDim2.new(random(2, 98) / 100, 0, 1.1 + random(0, 15) / 100, 0)
                o.BackgroundColor3 = col
                o.BackgroundTransparency = random(1, 5) / 10
                o.BorderSizePixel = 0
                o.ZIndex = 1
                o.Rotation = isLine and random(-15, 15) or random(-45, 45)
                Instance.new("UICorner", o).CornerRadius = UDim.new(1, 0)
                local dur = random(30, 60) / 10
                local targetX = o.Position.X.Scale + random(-20, 20) / 100
                local tween = ae:Create(o, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Position = UDim2.new(targetX, 0, -0.2, 0),
                    BackgroundTransparency = 1,
                    Rotation = o.Rotation + random(-180, 180),
                    Size = UDim2.fromOffset(0, 0),
                })
                tween:Play()
                tween.Completed:Connect(onCompleted)
            end
        end
        while loadingScreen and loadingScreen.Parent do
            pcall(tryOperation3)
            task.wait(random(15, 30) / 100)
        end
    end
    local function transformValue(text)
        local frame7 = Instance.new("Frame")
        frame7.Size = UDim2.new(0, 75, 1, 0)
        frame7.BackgroundTransparency = 1
        local frame8 = Instance.new("Frame", frame7)
        frame8.Size = UDim2.fromOffset(6, 6)
        frame8.Position = UDim2.new(0, 0, 0.5, -3)
        frame8.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
        frame8.BorderSizePixel = 0
        Instance.new("UICorner", frame8).CornerRadius = UDim.new(1, 0)
        local textLabel3 = Instance.new("TextLabel", frame7)
        textLabel3.Size = UDim2.new(1, -12, 1, 0)
        textLabel3.Position = UDim2.fromOffset(12, 0)
        textLabel3.BackgroundTransparency = 1
        textLabel3.Text = text
        textLabel3.Font = Enum.Font.GothamBold
        textLabel3.TextSize = 9
        textLabel3.TextColor3 = Color3.fromRGB(100, 85, 125)
        textLabel3.TextXAlignment = Enum.TextXAlignment.Left
        return frame7, frame8, textLabel3
    end
    local f, g, h, i, j
    local function backgroundTask7()
        local function animate2(w)
            if w == 1 and i and j then
                ae:Create(i, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(199, 125, 255)}):Play()
                ae:Create(j, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(230, 210, 255)}):Play()
            end
        end
        local function tryOperation2()
            ae:Create(b, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.52, 0),
            }):Play()
            for _, desc in ipairs(b:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    ae:Create(desc, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
                end
            end
            ae:Create(b, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            ae:Create(loadingScreen, TweenInfo.new(0.55), {BackgroundTransparency = 1}):Play()
        end
        local n = 0
        local o = 1
        animate2(1)
        while n < 7.5 and loadingScreen and loadingScreen.Parent do
            n = n + at.RenderStepped:Wait()
            local r = math.clamp(n / 7.5, 0, 1)
            local s = -(math.cos(math.pi * r) - 1) / 2
            g.Size = UDim2.new(s, 0, 1, 0)
            local t = math.floor(s * 100)
            h.Text = t .. "%"
            if t >= 35 and t < 75 and o < 2 then
                o = 2
                animate2(2)
            end
        end
        g.Size = UDim2.new(1, 0, 1, 0)
        h.Text = "100%"
        if f then
            f.Text = "FORKT COMMUNITY"
            ae:Create(f, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(120, 255, 170)}):Play()
        end
        task.wait(0.5)
        pcall(tryOperation2)
        task.wait(0.55)
        if loadingScreen and loadingScreen.Parent then
            loadingScreen.Visible = false
            loadingScreen:Destroy()
        end
    end

    loadingScreen = Instance.new("Frame", br.Screen)
    loadingScreen.Name = "LoadingScreen"
    loadingScreen.Size = UDim2.new(1, 0, 1, 0)
    loadingScreen.BackgroundColor3 = Color3.fromRGB(5, 3, 8)
    loadingScreen.BorderSizePixel = 0
    loadingScreen.ZIndex = 999

    b = Instance.new("Frame", loadingScreen)
    b.Size = UDim2.fromOffset(460, 290)
    b.Position = UDim2.fromScale(0.5, 0.5)
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundColor3 = Color3.fromRGB(16, 12, 24)
    b.BorderSizePixel = 0
    b.ClipsDescendants = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 16)

    local uIGradient2 = Instance.new("UIGradient", b)
    uIGradient2.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 19, 44)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 9, 18)),
    })
    uIGradient2.Rotation = 45

    local stroke = Instance.new("UIStroke", b)
    stroke.Color = Color3.fromRGB(199, 125, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.35

    a = Instance.new("UIScale", b)
    updateState8()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(performTask2)
    end

    d = Instance.new("Folder", b)
    e = {
        Color3.fromRGB(199, 125, 255),
        Color3.fromRGB(157, 78, 221),
        Color3.fromRGB(245, 240, 255),
        Color3.fromRGB(104, 57, 158),
    }
    task.spawn(backgroundTask6)

    local iconHolder = Instance.new("Frame", b)
    iconHolder.Size = UDim2.fromOffset(48, 48)
    iconHolder.Position = UDim2.new(0.5, -24, 0, 24)
    iconHolder.BackgroundColor3 = Color3.fromRGB(35, 24, 52)
    iconHolder.BorderSizePixel = 0
    iconHolder.ZIndex = 2
    Instance.new("UICorner", iconHolder).CornerRadius = UDim.new(0, 12)

    local iconStroke = Instance.new("UIStroke", iconHolder)
    iconStroke.Color = Color3.fromRGB(199, 125, 255)
    iconStroke.Transparency = 0.3

    local iconImg = Instance.new("ImageLabel", iconHolder)
    iconImg.Size = UDim2.fromOffset(24, 24)
    iconImg.Position = UDim2.fromScale(0.5, 0.5)
    iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = ag.PACKAGE
    iconImg.ImageColor3 = Color3.fromRGB(220, 160, 255)
    iconImg.ZIndex = 3

    local titleLbl = Instance.new("TextLabel", b)
    titleLbl.Size = UDim2.new(1, 0, 0, 24)
    titleLbl.Position = UDim2.new(0, 0, 0, 80)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "FORKT ENGINE"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 20
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.ZIndex = 2

    local subLbl = Instance.new("TextLabel", b)
    subLbl.Size = UDim2.new(1, 0, 0, 16)
    subLbl.Position = UDim2.new(0, 0, 0, 104)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "ADVANCED ASSET MANAGEMENT"
    subLbl.Font = Enum.Font.GothamBold
    subLbl.TextSize = 10
    subLbl.TextColor3 = Color3.fromRGB(150, 135, 175)
    subLbl.ZIndex = 2

    f = Instance.new("TextLabel", b)
    f.Size = UDim2.new(1, 0, 0, 20)
    f.Position = UDim2.new(0, 0, 0, 138)
    f.BackgroundTransparency = 1
    f.Text = "INITIALIZING CORE SYSTEM..."
    f.Font = Enum.Font.GothamBold
    f.TextSize = 11
    f.TextColor3 = Color3.fromRGB(199, 125, 255)
    f.ZIndex = 2

    local frame5 = Instance.new("Frame", b)
    frame5.Size = UDim2.new(0.8, 0, 0, 8)
    frame5.Position = UDim2.new(0.1, 0, 0, 168)
    frame5.BackgroundColor3 = Color3.fromRGB(10, 8, 15)
    frame5.BorderSizePixel = 0
    frame5.ZIndex = 2
    Instance.new("UICorner", frame5).CornerRadius = UDim.new(1, 0)

    local uIStroke3 = Instance.new("UIStroke", frame5)
    uIStroke3.Color = Color3.fromRGB(50, 40, 70)
    uIStroke3.Transparency = 0.5

    g = Instance.new("Frame", frame5)
    g.Size = UDim2.new(0, 0, 1, 0)
    g.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    g.BorderSizePixel = 0
    g.ZIndex = 3
    Instance.new("UICorner", g).CornerRadius = UDim.new(1, 0)

    local uIGradient3 = Instance.new("UIGradient", g)
    uIGradient3.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 60, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 130, 255)),
    })

    h = Instance.new("TextLabel", b)
    h.Size = UDim2.new(0.4, 0, 0, 20)
    h.Position = UDim2.new(0.1, 0, 0, 184)
    h.BackgroundTransparency = 1
    h.Text = "0%"
    h.Font = Enum.Font.GothamBold
    h.TextSize = 12
    h.TextColor3 = Color3.fromRGB(240, 230, 255)
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.ZIndex = 2

    local textLabel2 = Instance.new("TextLabel", b)
    textLabel2.Size = UDim2.new(0.4, 0, 0, 20)
    textLabel2.Position = UDim2.new(0.5, 0, 0, 184)
    textLabel2.BackgroundTransparency = 1
    textLabel2.Text = "v3.8.x PRO"
    textLabel2.Font = Enum.Font.GothamMedium
    textLabel2.TextSize = 11
    textLabel2.TextColor3 = Color3.fromRGB(120, 105, 145)
    textLabel2.TextXAlignment = Enum.TextXAlignment.Right
    textLabel2.ZIndex = 2

    local frame6 = Instance.new("Frame", b)
    frame6.Size = UDim2.new(0.85, 0, 0, 24)
    frame6.Position = UDim2.new(0.075, 0, 0, 230)
    frame6.BackgroundTransparency = 1
    frame6.ZIndex = 2

    local uIListLayout = Instance.new("UIListLayout", frame6)
    uIListLayout.FillDirection = Enum.FillDirection.Horizontal
    uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uIListLayout.Padding = UDim.new(0, 26)

    local c1, _, cLbl1 = transformValue("CORE")
    c1.Parent = frame6
    local c2, _, cLbl2 = transformValue("PARSER")
    c2.Parent = frame6
    local c3, _, cLbl3 = transformValue("IMPORTER")
    c3.Parent = frame6
    i = cLbl2
    j = cLbl3

    task.spawn(backgroundTask7)
end

local bs
local function connectEvents2()
    local a
    local function updateState3()
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local q = viewportSize.Y / 420
        a.Scale = math.min(viewportSize.X / 600, q, 1)
    end
    local frame9, b
    local function performTask()
        if frame9.Parent then
            b()
        end
    end
    b = updateState3
    local c, d, e
    local function onInputBegan(q)
        local r = q.UserInputType == Enum.UserInputType.MouseButton1 or q.UserInputType == Enum.UserInputType.Touch
        if r then
            c = true
            d = q.Position
            e = frame9.Position
        end
    end
    local function onInputChanged(q)
        if c and q.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = q.Position - d
            frame9.Position = UDim2.new(e.X.Scale, e.X.Offset + delta.X, e.Y.Scale, e.Y.Offset + delta.Y)
        end
    end
    local function onInputEnded(q)
        if q.UserInputType == Enum.UserInputType.MouseButton1 or q.UserInputType == Enum.UserInputType.Touch then
            c = false
        end
    end
    local f
    local function updateState4()
        br.Main.Visible = not br.Main.Visible
        f.Image = br.Main.Visible and ag.CHEVRON_RIGHT or ag.CHEVRON_LEFT
    end
    local g, h, i, j
    local function updateState5(q)
        if q.UserInputType == Enum.UserInputType.MouseButton1 or q.UserInputType == Enum.UserInputType.Touch then
            h = true
            i = q.Position
            j = g.Position
        end
    end
    local function updateState6(q)
        if h and q.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = q.Position - i
            g.Position = UDim2.new(j.X.Scale, j.X.Offset + delta.X, j.Y.Scale, j.Y.Offset + delta.Y)
        end
    end
    local function updateState7(q)
        if q.UserInputType == Enum.UserInputType.MouseButton1 or q.UserInputType == Enum.UserInputType.Touch then
            h = false
        end
    end
    local k
    local function onMouseEnter4()
        ae:Create(k, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(230, 60, 90),
            TextColor3 = Color3.new(1, 1, 1),
        }):Play()
    end
    local function onMouseLeave4()
        ae:Create(k, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(32, 24, 46),
            TextColor3 = Color3.fromRGB(220, 210, 240),
        }):Play()
    end
    local function onMouseButton1Click8()
        br.Main.Visible = false
        f.Image = ag.CHEVRON_LEFT
    end

    frame9 = Instance.new("Frame", br.Screen)
    frame9.Size = UDim2.fromOffset(560, 380)
    frame9.Position = UDim2.fromScale(0.5, 0.5)
    frame9.AnchorPoint = Vector2.new(0.5, 0.5)
    frame9.BackgroundColor3 = Color3.fromRGB(15, 12, 20)
    frame9.BorderSizePixel = 0
    frame9.ClipsDescendants = true
    Instance.new("UICorner", frame9).CornerRadius = UDim.new(0, 10)

    local uIStroke4 = Instance.new("UIStroke", frame9)
    uIStroke4.Color = Color3.fromRGB(157, 78, 221)
    uIStroke4.Thickness = 1.5
    uIStroke4.Transparency = 0.3
    br.Main = frame9

    a = Instance.new("UIScale", frame9)
    updateState3()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(performTask)
    end

    frame9.InputBegan:Connect(onInputBegan)
    if bs then
        bs.InputChanged:Connect(onInputChanged)
        bs.InputEnded:Connect(onInputEnded)
    end

    local l = Instance.new("Frame", frame9)
    l.Size = UDim2.new(0, 185, 1, 0)
    l.BackgroundColor3 = Color3.fromRGB(18, 14, 25)
    l.BorderSizePixel = 0
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 10)

    local uIStroke5 = Instance.new("UIStroke", l)
    uIStroke5.Color = Color3.fromRGB(157, 78, 221)
    uIStroke5.Transparency = 0.6
    uIStroke5.Thickness = 1

    local uIGradient4 = Instance.new("UIGradient", l)
    uIGradient4.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 17, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 9, 18)),
    })
    uIGradient4.Rotation = 90
    br.Sidebar = l

    local m = Instance.new("Frame", l)
    m.Size = UDim2.fromOffset(32, 32)
    m.Position = UDim2.fromOffset(14, 16)
    m.BackgroundColor3 = Color3.fromRGB(32, 24, 46)
    Instance.new("UICorner", m).CornerRadius = UDim.new(0, 8)

    local uIStroke6 = Instance.new("UIStroke", m)
    uIStroke6.Color = Color3.fromRGB(199, 125, 255)
    uIStroke6.Transparency = 0.4

    local imageLabel = Instance.new("ImageLabel", m)
    imageLabel.Size = UDim2.fromOffset(25, 25)
    imageLabel.Position = UDim2.fromScale(0.5, 0.5)
    imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = ag.PACKAGE
    imageLabel.ImageColor3 = Color3.fromRGB(210, 150, 255)

    local textLabel4 = Instance.new("TextLabel", l)
    textLabel4.Size = UDim2.new(1, -60, 0, 16)
    textLabel4.Position = UDim2.fromOffset(56, 16)
    textLabel4.BackgroundTransparency = 1
    textLabel4.Text = "FORKT ENGINE"
    textLabel4.Font = Enum.Font.GothamBold
    textLabel4.TextSize = 13
    textLabel4.TextColor3 = Color3.fromRGB(245, 240, 255)
    textLabel4.TextXAlignment = Enum.TextXAlignment.Left

    local textLabel5 = Instance.new("TextLabel", l)
    textLabel5.Size = UDim2.new(1, -60, 0, 14)
    textLabel5.Position = UDim2.fromOffset(56, 34)
    textLabel5.BackgroundTransparency = 1
    textLabel5.Text = "v3.8.x PRO"
    textLabel5.Font = Enum.Font.GothamMedium
    textLabel5.TextSize = 10
    textLabel5.TextColor3 = Color3.fromRGB(160, 140, 190)
    textLabel5.TextXAlignment = Enum.TextXAlignment.Left

    local n = Instance.new("Frame", l)
    n.Size = UDim2.new(1, -28, 0, 1)
    n.Position = UDim2.fromOffset(14, 64)
    n.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
    n.BorderSizePixel = 0

    local o = Instance.new("Frame", frame9)
    o.Size = UDim2.new(1, -185, 1, 0)
    o.Position = UDim2.new(0, 185, 0, 0)
    o.BackgroundTransparency = 1
    o.ClipsDescendants = true
    Instance.new("UICorner", o).CornerRadius = UDim.new(0, 10)
    br.ContentContainer = o

    g = Instance.new("ImageButton", br.Screen)
    g.Size = UDim2.fromOffset(40, 40)
    g.Position = UDim2.new(0, 15, 0, 50)
    g.BackgroundColor3 = Color3.fromRGB(22, 18, 30)
    g.Image = ""
    Instance.new("UICorner", g).CornerRadius = UDim.new(0, 10)

    local toggleStroke = Instance.new("UIStroke", g)
    toggleStroke.Color = Color3.fromRGB(157, 78, 221)

    f = Instance.new("ImageLabel", g)
    f.Size = UDim2.fromOffset(20, 20)
    f.Position = UDim2.fromScale(0.5, 0.5)
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BackgroundTransparency = 1
    f.Image = ag.CHEVRON_RIGHT
    f.ImageColor3 = Color3.fromRGB(199, 125, 255)

    g.MouseButton1Click:Connect(updateState4)
    g.InputBegan:Connect(updateState5)
    if bs then
        bs.InputChanged:Connect(updateState6)
        bs.InputEnded:Connect(updateState7)
    end

    k = Instance.new("TextButton", frame9)
    k.Size = UDim2.fromOffset(26, 26)
    k.Position = UDim2.new(1, -38, 0, 12)
    k.BackgroundColor3 = Color3.fromRGB(32, 24, 46)
    k.Text = "×"
    k.Font = Enum.Font.GothamBold
    k.TextSize = 18
    k.TextColor3 = Color3.fromRGB(220, 210, 240)
    Instance.new("UICorner", k).CornerRadius = UDim.new(0, 8)
    k.MouseEnter:Connect(onMouseEnter4)
    k.MouseLeave:Connect(onMouseLeave4)
    k.MouseButton1Click:Connect(onMouseButton1Click8)
end

local bt
local function computeValue7()
    local a
    local function backgroundTask5()
        local function tryOperation()
            local players = game:GetService("Players")
            local thumb = players:GetUserThumbnailAsync(al.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            if thumb then
                a.Image = thumb
            end
        end
        pcall(tryOperation)
    end
    local b
    local function updateState2(text, i, j, k)
        local l = Instance.new("Frame", b)
        l.Size = UDim2.new(0.48, 0, 1, 0)
        l.Position = UDim2.new(j, 0, 0, 0)
        l.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 10)
        local uIStroke9 = Instance.new("UIStroke", l)
        uIStroke9.Color = k and Color3.fromRGB(199, 125, 255) or Color3.fromRGB(50, 40, 70)
        uIStroke9.Transparency = k and 0.2 or 0.5
        local m = Instance.new("TextLabel", l)
        m.Size = UDim2.new(1, -16, 0, 18)
        m.Position = UDim2.fromOffset(12, 10)
        m.BackgroundTransparency = 1
        m.Text = i
        m.Font = Enum.Font.GothamBold
        m.TextSize = 12
        m.TextColor3 = k and Color3.fromRGB(230, 210, 255) or Color3.fromRGB(210, 150, 255)
        m.TextXAlignment = Enum.TextXAlignment.Left
        local n = Instance.new("TextLabel", l)
        n.Size = UDim2.new(1, -16, 0, 14)
        n.Position = UDim2.fromOffset(12, 28)
        n.BackgroundTransparency = 1
        n.Text = text
        n.Font = Enum.Font.Gotham
        n.TextSize = 10
        n.TextColor3 = Color3.fromRGB(150, 140, 175)
        n.TextXAlignment = Enum.TextXAlignment.Left
    end

    local contentContainer = br.ContentContainer
    local c = Instance.new("Frame", contentContainer)
    c.Size = UDim2.new(1, 0, 1, 0)
    c.BackgroundTransparency = 1
    c.Visible = false
    br.OverviewView = c

    local uIPadding3 = Instance.new("UIPadding", c)
    uIPadding3.PaddingTop = UDim.new(0, 20)
    uIPadding3.PaddingBottom = UDim.new(0, 20)
    uIPadding3.PaddingLeft = UDim.new(0, 20)
    uIPadding3.PaddingRight = UDim.new(0, 20)

    local layout = Instance.new("UIListLayout", c)
    layout.Padding = UDim.new(0, 14)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local textLabel6 = Instance.new("TextLabel", c)
    textLabel6.Size = UDim2.new(1, 0, 0, 24)
    textLabel6.BackgroundTransparency = 1
    textLabel6.Text = "System Profile"
    textLabel6.Font = Enum.Font.GothamBold
    textLabel6.TextSize = 17
    textLabel6.TextColor3 = Color3.fromRGB(245, 240, 255)
    textLabel6.TextXAlignment = Enum.TextXAlignment.Left
    textLabel6.LayoutOrder = 1

    local d = Instance.new("Frame", c)
    d.Size = UDim2.new(1, 0, 0, 85)
    d.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
    d.LayoutOrder = 2
    Instance.new("UICorner", d).CornerRadius = UDim.new(0, 12)

    local uIStroke7 = Instance.new("UIStroke", d)
    uIStroke7.Color = Color3.fromRGB(157, 78, 221)
    uIStroke7.Transparency = 0.5
    uIStroke7.Thickness = 1.2

    local uIGradient5 = Instance.new("UIGradient", d)
    uIGradient5.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 26, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 13, 26)),
    })
    uIGradient5.Rotation = 45

    local new2 = Instance.new("Frame", d)
    new2.Size = UDim2.fromOffset(52, 52)
    new2.Position = UDim2.fromOffset(16, 16)
    new2.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
    Instance.new("UICorner", new2).CornerRadius = UDim.new(1, 0)

    local e = Instance.new("UIStroke", new2)
    e.Color = Color3.fromRGB(199, 125, 255)
    e.Thickness = 1.5

    a = Instance.new("ImageLabel", new2)
    a.Size = UDim2.fromScale(1, 1)
    a.BackgroundTransparency = 1
    a.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    Instance.new("UICorner", a).CornerRadius = UDim.new(1, 0)
    task.spawn(backgroundTask5)

    local new3 = Instance.new("TextLabel", d)
    new3.Size = UDim2.new(1, -90, 0, 20)
    new3.Position = UDim2.fromOffset(82, 18)
    new3.BackgroundTransparency = 1
    new3.Text = al.DisplayName
    new3.Font = Enum.Font.GothamBold
    new3.TextSize = 15
    new3.TextColor3 = Color3.fromRGB(250, 240, 255)
    new3.TextXAlignment = Enum.TextXAlignment.Left
    new3.TextTruncate = Enum.TextTruncate.AtEnd

    local textLabel7 = Instance.new("TextLabel", d)
    textLabel7.Size = UDim2.new(1, -90, 0, 16)
    textLabel7.Position = UDim2.fromOffset(82, 40)
    textLabel7.BackgroundTransparency = 1
    textLabel7.Text = "@" .. al.Name .. "  •  ID: " .. tostring(al.UserId)
    textLabel7.Font = Enum.Font.Gotham
    textLabel7.TextSize = 11
    textLabel7.TextColor3 = Color3.fromRGB(175, 165, 195)
    textLabel7.TextXAlignment = Enum.TextXAlignment.Left

    b = Instance.new("Frame", c)
    b.Size = UDim2.new(1, 0, 0, 52)
    b.BackgroundTransparency = 1
    b.LayoutOrder = 3

    local f = true
    updateState2("Status Access", "Premium Unlocked", 0, f)
    updateState2("Core Engine", "Studio Lite", 0.52, false)

    local h = Instance.new("Frame", c)
    h.Size = UDim2.new(1, 0, 0, 56)
    h.BackgroundColor3 = Color3.fromRGB(18, 12, 26)
    h.LayoutOrder = 4
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 10)

    local uIStroke8 = Instance.new("UIStroke", h)
    uIStroke8.Color = Color3.fromRGB(70, 50, 90)
    uIStroke8.Transparency = 0.5

    local g = Instance.new("Frame", h)
    g.Size = UDim2.fromOffset(32, 32)
    g.Position = UDim2.fromOffset(12, 12)
    g.BackgroundColor3 = Color3.fromRGB(157, 78, 221)
    g.BackgroundTransparency = 0.8
    Instance.new("UICorner", g).CornerRadius = UDim.new(0, 8)

    local imageLabel2 = Instance.new("ImageLabel", g)
    imageLabel2.Size = UDim2.fromOffset(25, 25)
    imageLabel2.Position = UDim2.fromScale(0.5, 0.5)
    imageLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
    imageLabel2.BackgroundTransparency = 1
    imageLabel2.Image = ag.PACKAGE
    imageLabel2.ImageColor3 = Color3.fromRGB(199, 125, 255)

    local textLabel8 = Instance.new("TextLabel", h)
    textLabel8.Size = UDim2.new(1, -64, 0, 18)
    textLabel8.Position = UDim2.fromOffset(56, 10)
    textLabel8.BackgroundTransparency = 1
    textLabel8.Text = "Forkt Community"
    textLabel8.Font = Enum.Font.GothamBold
    textLabel8.TextSize = 13
    textLabel8.TextColor3 = Color3.fromRGB(245, 240, 255)
    textLabel8.TextXAlignment = Enum.TextXAlignment.Left

    local textLabel9 = Instance.new("TextLabel", h)
    textLabel9.Size = UDim2.new(1, -64, 0, 16)
    textLabel9.Position = UDim2.fromOffset(56, 28)
    textLabel9.BackgroundTransparency = 1
    textLabel9.Text = "Developed By @sukitov"
    textLabel9.Font = Enum.Font.GothamMedium
    textLabel9.TextSize = 10
    textLabel9.TextColor3 = Color3.fromRGB(199, 125, 255)
    textLabel9.TextXAlignment = Enum.TextXAlignment.Left
end

local function connectEvents3()
    local a
    local function createTextLabel(l, text, m)
        local n = Instance.new("Frame", a)
        n.Size = UDim2.new(0.48, 0, 1, 0)
        n.Position = UDim2.new(l, 0, 0, 0)
        n.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
        Instance.new("UICorner", n).CornerRadius = UDim.new(0, 10)
        local o = Instance.new("UIStroke", n)
        o.Color = Color3.fromRGB(157, 78, 221)
        o.Transparency = 0.5
        o.Thickness = 1.2
        local uIGradient7 = Instance.new("UIGradient", n)
        uIGradient7.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 22, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 12, 28)),
        })
        uIGradient7.Rotation = 45
        local lblVal = Instance.new("TextLabel", n)
        lblVal.Size = UDim2.new(1, -16, 0, 20)
        lblVal.Position = UDim2.fromOffset(12, 8)
        lblVal.BackgroundTransparency = 1
        lblVal.Text = m
        lblVal.Font = Enum.Font.GothamBold
        lblVal.TextSize = 18
        lblVal.TextColor3 = Color3.fromRGB(245, 240, 255)
        lblVal.TextXAlignment = Enum.TextXAlignment.Left
        local lblTitle = Instance.new("TextLabel", n)
        lblTitle.Size = UDim2.new(1, -16, 0, 14)
        lblTitle.Position = UDim2.fromOffset(12, 30)
        lblTitle.BackgroundTransparency = 1
        lblTitle.Text = text
        lblTitle.Font = Enum.Font.GothamMedium
        lblTitle.TextSize = 10
        lblTitle.TextColor3 = Color3.fromRGB(165, 155, 185)
        lblTitle.TextXAlignment = Enum.TextXAlignment.Left
        return lblVal
    end
    local b
    local tabs = {}
    local function createTextButton(text, l)
        local textButton2 = Instance.new("TextButton", b)
        textButton2.Size = UDim2.new(0.333, 0, 1, 0)
        textButton2.Position = UDim2.new((l - 1) * 0.333, 0, 0, 0)
        textButton2.BackgroundTransparency = 1
        textButton2.Text = text
        textButton2.Font = Enum.Font.GothamBold
        textButton2.TextSize = 11
        textButton2.TextColor3 = l == 1 and Color3.new(1, 1, 1) or Color3.fromRGB(140, 130, 165)
        textButton2.ZIndex = 2
        table.insert(tabs, textButton2)
        return textButton2
    end
    local c, d
    local function processItems(currentFileFilter, l, m)
        if _G.CurrentFileFilter == currentFileFilter then
            return
        end
        _G.CurrentFileFilter = currentFileFilter
        ae:Create(c, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new((l - 1) * 0.333, 2, 0, 2),
        }):Play()
        for _, tabBtn in ipairs(tabs) do
            ae:Create(tabBtn, TweenInfo.new(0.25), {
                TextColor3 = tabBtn == m and Color3.new(1, 1, 1) or Color3.fromRGB(140, 130, 165),
            }):Play()
        end
        for _, child in ipairs(d:GetChildren()) do
            if child:IsA("Frame") and child:GetAttribute("FileType") then
                local r = child:GetAttribute("FileType")
                local mapped = (r == "RBXM" or r == "RBXMX") and "MODEL" or "PLACE"
                child.Visible = currentFileFilter == "ALL" or mapped == currentFileFilter
            end
        end
    end

    local contentContainer2 = br.ContentContainer
    local i = Instance.new("Frame", contentContainer2)
    i.Size = UDim2.new(1, 0, 1, 0)
    i.BackgroundTransparency = 1
    i.Visible = true
    br.AssetsView = i

    local j = Instance.new("TextLabel", i)
    j.Size = UDim2.new(1, -40, 0, 22)
    j.Position = UDim2.fromOffset(20, 20)
    j.BackgroundTransparency = 1
    j.Text = "Dashboard"
    j.Font = Enum.Font.GothamBold
    j.TextSize = 17
    j.TextColor3 = Color3.fromRGB(245, 240, 255)
    j.TextXAlignment = Enum.TextXAlignment.Left

    local descLbl = Instance.new("TextLabel", i)
    descLbl.Size = UDim2.new(1, -40, 0, 14)
    descLbl.Position = UDim2.fromOffset(20, 44)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = "Manage your local Roblox assets seamlessly."
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 11
    descLbl.TextColor3 = Color3.fromRGB(165, 155, 185)
    descLbl.TextXAlignment = Enum.TextXAlignment.Left

    a = Instance.new("Frame", i)
    a.Size = UDim2.new(1, -40, 0, 54)
    a.Position = UDim2.fromOffset(20, 68)
    a.BackgroundTransparency = 1
    br.lblFiles = createTextLabel(0, "TOTAL ASSETS", "0")
    br.lblRBXM = createTextLabel(0.52, "ASSET READY", "0")

    b = Instance.new("Frame", i)
    b.Size = UDim2.new(1, -40, 0, 32)
    b.Position = UDim2.fromOffset(20, 134)
    b.BackgroundColor3 = Color3.fromRGB(18, 14, 25)
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)

    local k = Instance.new("UIStroke", b)
    k.Color = Color3.fromRGB(50, 40, 70)
    k.Transparency = 0.5
    k.Thickness = 1.2

    c = Instance.new("Frame", b)
    c.Size = UDim2.new(0.333, -4, 1, -4)
    c.Position = UDim2.new(0, 2, 0, 2)
    c.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0)

    local uIGradient6 = Instance.new("UIGradient", c)
    uIGradient6.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(199, 125, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 50, 200)),
    })

    local e = createTextButton("ALL", 1)
    local g = createTextButton("MODEL", 2)
    local h = createTextButton("PLACE", 3)
    _G.CurrentFileFilter = "ALL"

    d = Instance.new("ScrollingFrame", i)
    br.Scroll = d

    e.MouseButton1Click:Connect(function()
        processItems("ALL", 1, e)
    end)
    g.MouseButton1Click:Connect(function()
        processItems("MODEL", 2, g)
    end)
    h.MouseButton1Click:Connect(function()
        processItems("PLACE", 3, h)
    end)

    d.Size = UDim2.new(1, -40, 1, -182)
    d.Position = UDim2.fromOffset(20, 178)
    d.BackgroundTransparency = 1
    d.ScrollBarThickness = 2
    d.ScrollBarImageColor3 = Color3.fromRGB(157, 78, 221)
    d.AutomaticCanvasSize = Enum.AutomaticSize.Y
    d.CanvasSize = UDim2.new(0, 0, 0, 0)

    local uIListLayout2 = Instance.new("UIListLayout", d)
    uIListLayout2.Padding = UDim.new(0, 10)
    uIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
end

local function updateState10()
    local contentContainer3 = br.ContentContainer
    local a = Instance.new("Frame", contentContainer3)
    a.Size = UDim2.new(1, 0, 1, 0)
    a.BackgroundTransparency = 1
    a.Visible = false
    br.SettingsView = a

    local uIPadding4 = Instance.new("UIPadding", a)
    uIPadding4.PaddingTop = UDim.new(0, 20)
    uIPadding4.PaddingBottom = UDim.new(0, 20)
    uIPadding4.PaddingLeft = UDim.new(0, 20)
    uIPadding4.PaddingRight = UDim.new(0, 20)

    local layout = Instance.new("UIListLayout", a)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local b = Instance.new("TextLabel", a)
    b.Size = UDim2.new(1, 0, 0, 24)
    b.BackgroundTransparency = 1
    b.Text = "About & Information"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 17
    b.TextColor3 = Color3.fromRGB(245, 240, 255)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = 1

    local c = Instance.new("Frame", a)
    c.Size = UDim2.new(1, 0, 0, 100)
    c.BackgroundColor3 = Color3.fromRGB(24, 16, 35)
    c.LayoutOrder = 2
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 12)

    local d = Instance.new("UIStroke", c)
    d.Color = Color3.fromRGB(157, 78, 221)
    d.Transparency = 0.4
    d.Thickness = 1.2

    local uIGradient8 = Instance.new("UIGradient", c)
    uIGradient8.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 25, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 12, 28)),
    })
    uIGradient8.Rotation = 45

    local new6 = Instance.new("Frame", c)
    new6.Size = UDim2.fromOffset(42, 42)
    new6.Position = UDim2.fromOffset(14, 14)
    new6.BackgroundColor3 = Color3.fromRGB(157, 78, 221)
    new6.BackgroundTransparency = 0.8
    Instance.new("UICorner", new6).CornerRadius = UDim.new(0, 10)

    local e = Instance.new("UIStroke", new6)
    e.Color = Color3.fromRGB(199, 125, 255)
    e.Transparency = 0.5

    local pkgImg = Instance.new("ImageLabel", new6)
    pkgImg.Size = UDim2.fromOffset(25, 25)
    pkgImg.Position = UDim2.fromScale(0.5, 0.5)
    pkgImg.AnchorPoint = Vector2.new(0.5, 0.5)
    pkgImg.BackgroundTransparency = 1
    pkgImg.Image = ag.PACKAGE
    pkgImg.ImageColor3 = Color3.fromRGB(245, 240, 255)

    local commLbl = Instance.new("TextLabel", c)
    commLbl.Size = UDim2.new(1, -80, 0, 22)
    commLbl.Position = UDim2.fromOffset(68, 12)
    commLbl.BackgroundTransparency = 1
    commLbl.Text = "Forkt Community"
    commLbl.Font = Enum.Font.GothamBold
    commLbl.TextSize = 15
    commLbl.TextColor3 = Color3.fromRGB(250, 245, 255)
    commLbl.TextXAlignment = Enum.TextXAlignment.Left

    local f = Instance.new("TextLabel", c)
    f.Size = UDim2.new(1, -80, 0, 18)
    f.Position = UDim2.fromOffset(68, 34)
    f.BackgroundTransparency = 1
    f.Text = "Advanced Asset Importer & Tools Studio Lite"
    f.Font = Enum.Font.GothamMedium
    f.TextSize = 10
    f.TextColor3 = Color3.fromRGB(180, 170, 200)
    f.TextXAlignment = Enum.TextXAlignment.Left

    local g = Instance.new("Frame", c)
    g.Size = UDim2.new(1, -28, 0, 1)
    g.Position = UDim2.fromOffset(14, 64)
    g.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
    g.BorderSizePixel = 0
    g.BackgroundTransparency = 0.5

    local h = Instance.new("TextLabel", c)
    h.Size = UDim2.new(0.5, -20, 0, 20)
    h.Position = UDim2.fromOffset(14, 70)
    h.BackgroundTransparency = 1
    h.Text = "Developer: @sukitov"
    h.Font = Enum.Font.GothamBold
    h.TextSize = 11
    h.TextColor3 = Color3.fromRGB(199, 125, 255)
    h.TextXAlignment = Enum.TextXAlignment.Left

    local i = Instance.new("TextLabel", c)
    i.Size = UDim2.new(0.5, -20, 0, 20)
    i.Position = UDim2.new(0.5, 6, 0, 70)
    i.BackgroundTransparency = 1
    i.Text = "Credits: @forkthubx"
    i.Font = Enum.Font.GothamBold
    i.TextSize = 11
    i.TextColor3 = Color3.fromRGB(199, 125, 255)
    i.TextXAlignment = Enum.TextXAlignment.Right
end

local bu
local function connectEvents4()
    local a
    local function updateState(text, layoutOrder)
        local m = Instance.new("Frame", a)
        m.Size = UDim2.new(1, 0, 0, 16)
        m.BackgroundTransparency = 1
        m.LayoutOrder = layoutOrder
        local imageLabel3 = Instance.new("ImageLabel", m)
        imageLabel3.Size = UDim2.fromOffset(15, 15)
        imageLabel3.Position = UDim2.new(0, 0, 0.5, -7)
        imageLabel3.BackgroundTransparency = 1
        imageLabel3.Image = ag.CHECK
        imageLabel3.ImageColor3 = Color3.fromRGB(120, 255, 170)
        local n = Instance.new("TextLabel", m)
        n.Size = UDim2.new(1, -22, 1, 0)
        n.Position = UDim2.fromOffset(22, 0)
        n.BackgroundTransparency = 1
        n.Text = text
        n.Font = Enum.Font.GothamMedium
        n.TextSize = 11
        n.TextColor3 = Color3.fromRGB(220, 215, 235)
        n.TextXAlignment = Enum.TextXAlignment.Left
    end
    local b
    local function onMouseButton1Click3()
        if ab and type(ab.setclipboard) == "function" then
            pcall(ab.setclipboard, "https://discord.gg/fpr9JJPAsr")
        end
        b.Text = "Discord Link Copied!"
        if bu then
            bu("Store", "Link Discord pembelian resmi disalin ke clipboard!", false)
        end
        task.delay(2.5, function()
            if b and b.Parent then
                b.Text = "Join Discord to Purchase"
            end
        end)
    end
    local c
    local function onMouseButton1Click4()
        if ab and type(ab.setclipboard) == "function" then
            pcall(ab.setclipboard, al.Name)
        end
        c.Text = "COPIED"
        c.BackgroundColor3 = Color3.fromRGB(157, 78, 221)
        c.TextColor3 = Color3.new(1, 1, 1)
        task.delay(1.5, function()
            if c and c.Parent then
                c.Text = "COPY"
                c.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
                c.TextColor3 = Color3.fromRGB(210, 180, 255)
            end
        end)
    end

    local contentContainer4 = br.ContentContainer
    local d = Instance.new("Frame", contentContainer4)
    d.Size = UDim2.new(1, 0, 1, 0)
    d.BackgroundTransparency = 1
    d.Visible = false
    br.BuyAccessView = d

    local uIPadding5 = Instance.new("UIPadding", d)
    uIPadding5.PaddingTop = UDim.new(0, 16)
    uIPadding5.PaddingBottom = UDim.new(0, 16)
    uIPadding5.PaddingLeft = UDim.new(0, 20)
    uIPadding5.PaddingRight = UDim.new(0, 20)

    local layout = Instance.new("UIListLayout", d)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local e = Instance.new("TextLabel", d)
    e.Size = UDim2.new(1, 0, 0, 20)
    e.BackgroundTransparency = 1
    e.Text = "Unlock Full Potential"
    e.Font = Enum.Font.GothamBold
    e.TextSize = 17
    e.TextColor3 = Color3.fromRGB(255, 255, 255)
    e.TextXAlignment = Enum.TextXAlignment.Left
    e.LayoutOrder = 1

    local f = Instance.new("Frame", d)
    f.Size = UDim2.new(1, 0, 0, 195)
    f.BackgroundTransparency = 1
    f.LayoutOrder = 2

    local g = Instance.new("Frame", f)
    g.Size = UDim2.new(1, 0, 1, 0)
    g.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
    g.ZIndex = 1
    Instance.new("UICorner", g).CornerRadius = UDim.new(0, 12)

    local h = Instance.new("UIStroke", g)
    h.Color = Color3.fromRGB(199, 125, 255)
    h.Thickness = 1.5
    h.Transparency = 0.2

    local uIGradient9 = Instance.new("UIGradient", g)
    uIGradient9.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 25, 75)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 12, 28)),
    })
    uIGradient9.Rotation = 45

    local new7 = Instance.new("Frame", g)
    new7.Size = UDim2.fromOffset(85, 22)
    new7.Position = UDim2.new(1, -95, 0, 14)
    new7.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", new7).CornerRadius = UDim.new(1, 0)

    local badgeGrad = Instance.new("UIGradient", new7)
    badgeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 150, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(157, 78, 221)),
    })

    local badgeLbl = Instance.new("TextLabel", new7)
    badgeLbl.Size = UDim2.fromScale(1, 1)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Text = "★ VIP ACCESS"
    badgeLbl.Font = Enum.Font.GothamBold
    badgeLbl.TextSize = 9
    badgeLbl.TextColor3 = Color3.fromRGB(20, 10, 35)

    local licLbl = Instance.new("TextLabel", g)
    licLbl.Size = UDim2.new(1, -28, 0, 20)
    licLbl.Position = UDim2.fromOffset(18, 14)
    licLbl.BackgroundTransparency = 1
    licLbl.Text = "LIFETIME LICENSE"
    licLbl.Font = Enum.Font.GothamBold
    licLbl.TextSize = 12
    licLbl.TextColor3 = Color3.fromRGB(200, 180, 230)
    licLbl.TextXAlignment = Enum.TextXAlignment.Left

    local priceLbl = Instance.new("TextLabel", g)
    priceLbl.Size = UDim2.new(1, -28, 0, 26)
    priceLbl.Position = UDim2.fromOffset(18, 32)
    priceLbl.BackgroundTransparency = 1
    priceLbl.Text = "Rp 15.000"
    priceLbl.Font = Enum.Font.GothamBlack
    priceLbl.TextSize = 22
    priceLbl.TextColor3 = Color3.new(1, 1, 1)
    priceLbl.TextXAlignment = Enum.TextXAlignment.Left

    a = Instance.new("Frame", g)
    a.Size = UDim2.new(1, -36, 0, 70)
    a.Position = UDim2.fromOffset(18, 68)
    a.BackgroundTransparency = 1

    local uIListLayout3 = Instance.new("UIListLayout", a)
    uIListLayout3.Padding = UDim.new(0, 6)
    uIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder

    updateState("Unlimited Import & Execution", 1)
    updateState("Unlock All Premium Studio Tools", 2)
    updateState("Free Lifetime Updates & Support", 3)

    b = Instance.new("TextButton", g)
    b.Size = UDim2.new(1, -36, 0, 36)
    b.Position = UDim2.new(0.5, 0, 1, -14)
    b.AnchorPoint = Vector2.new(0.5, 1)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = "Join Discord to Purchase"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(1, 1, 1)
    b.ZIndex = 3
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    local j = Instance.new("UIGradient", b)
    j.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 95, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 40, 175)),
    })
    b.MouseButton1Click:Connect(onMouseButton1Click3)

    local new9 = Instance.new("Frame", d)
    new9.Size = UDim2.new(1, 0, 0, 42)
    new9.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
    new9.LayoutOrder = 3
    Instance.new("UICorner", new9).CornerRadius = UDim.new(0, 10)

    local k = Instance.new("UIStroke", new9)
    k.Color = Color3.fromRGB(50, 40, 70)
    k.Transparency = 0.5

    local nameLbl = Instance.new("TextLabel", new9)
    nameLbl.Size = UDim2.new(1, -90, 1, 0)
    nameLbl.Position = UDim2.fromOffset(14, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = "Your Name: " .. al.Name
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 11
    nameLbl.TextColor3 = Color3.fromRGB(180, 175, 200)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    c = Instance.new("TextButton", new9)
    c.Size = UDim2.fromOffset(70, 26)
    c.Position = UDim2.new(1, -80, 0.5, -13)
    c.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
    c.Text = "COPY"
    c.Font = Enum.Font.GothamBold
    c.TextSize = 10
    c.TextColor3 = Color3.fromRGB(210, 180, 255)
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("UIStroke", c)
    l.Color = Color3.fromRGB(157, 78, 221)
    l.Transparency = 0.4
    c.MouseButton1Click:Connect(onMouseButton1Click4)
end

local function connectEvents5()
    local navItems = {}
    local function animate(j)
        br.OverviewView.Visible = j == "Overview"
        br.AssetsView.Visible = j == "Assets"
        br.SettingsView.Visible = j == "Settings"
        br.BuyAccessView.Visible = j == "Buy Access"

        for name, item in pairs(navItems) do
            local active = name == j
            local isBuy = name == "Buy Access"
            ae:Create(item.ActiveBar, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = active and UDim2.new(0, 3, 0, 18) or UDim2.new(0, 3, 0, 0),
                BackgroundTransparency = active and 0 or 1,
            }):Play()

            if isBuy then
                ae:Create(item.Button, TweenInfo.new(0.2), {
                    BackgroundTransparency = active and 0 or 0.82,
                    BackgroundColor3 = Color3.fromRGB(157, 78, 221),
                }):Play()
                ae:Create(item.Label, TweenInfo.new(0.2), {
                    TextColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(230, 180, 255),
                }):Play()
                ae:Create(item.Icon, TweenInfo.new(0.2), {
                    ImageColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(230, 180, 255),
                }):Play()
            else
                ae:Create(item.Button, TweenInfo.new(0.2), {
                    BackgroundTransparency = active and 0 or 1,
                    BackgroundColor3 = active and Color3.fromRGB(38, 28, 55) or Color3.fromRGB(22, 18, 30),
                }):Play()
                ae:Create(item.Label, TweenInfo.new(0.2), {
                    TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 150, 180),
                }):Play()
                ae:Create(item.Icon, TweenInfo.new(0.2), {
                    ImageColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 150, 180),
                }):Play()
            end
        end
    end

    local b = Instance.new("Frame", br.Sidebar)
    b.Size = UDim2.new(1, 0, 0, 160)
    b.Position = UDim2.fromOffset(0, 80)
    b.BackgroundTransparency = 1

    local uIListLayout4 = Instance.new("UIListLayout", b)
    uIListLayout4.Padding = UDim.new(0, 6)
    uIListLayout4.SortOrder = Enum.SortOrder.LayoutOrder
    uIListLayout4.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function connectEvents(text, image, layoutOrder, j)
        local btn = Instance.new("TextButton", b)
        btn.Size = UDim2.new(1, -28, 0, 36)
        btn.BackgroundColor3 = j and Color3.fromRGB(157, 78, 221) or Color3.fromRGB(22, 18, 30)
        btn.BackgroundTransparency = j and 0.82 or 1
        btn.Text = ""
        btn.LayoutOrder = layoutOrder
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local activeBar = Instance.new("Frame", btn)
        activeBar.Size = UDim2.new(0, 3, 0, 0)
        activeBar.Position = UDim2.new(0, 0, 0.5, 0)
        activeBar.AnchorPoint = Vector2.new(0, 0.5)
        activeBar.BackgroundColor3 = j and Color3.new(1, 1, 1) or Color3.fromRGB(199, 125, 255)
        activeBar.BorderSizePixel = 0
        Instance.new("UICorner", activeBar).CornerRadius = UDim.new(1, 0)

        local icon = Instance.new("ImageLabel", btn)
        icon.Size = UDim2.fromOffset(16, 16)
        icon.Position = UDim2.new(0, 14, 0.5, -8)
        icon.BackgroundTransparency = 1
        icon.Image = image
        icon.ImageColor3 = j and Color3.fromRGB(230, 180, 255) or Color3.fromRGB(160, 150, 180)

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1, -44, 1, 0)
        lbl.Position = UDim2.fromOffset(40, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 11
        lbl.TextColor3 = j and Color3.fromRGB(230, 180, 255) or Color3.fromRGB(160, 150, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        navItems[text] = {Button = btn, Icon = icon, Label = lbl, ActiveBar = activeBar}
        btn.MouseButton1Click:Connect(function()
            animate(text)
        end)
        btn.MouseEnter:Connect(function()
            ae:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = j and 0.5 or 0,
                BackgroundColor3 = j and Color3.fromRGB(157, 78, 221) or Color3.fromRGB(30, 22, 45),
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            ae:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = j and 0.82 or 1,
                BackgroundColor3 = j and Color3.fromRGB(157, 78, 221) or Color3.fromRGB(22, 18, 30),
            }):Play()
        end)
    end

    connectEvents("Overview", ag.DASHBOARD, 1, false)
    connectEvents("Assets", ag.FOLDER, 2, false)
    connectEvents("Settings", ag.SETTINGS, 3, false)
    connectEvents("Buy Access", ag.DOWNLOAD, 4, true)
    animate("Overview")

    local h = Instance.new("Frame", br.Sidebar)
    h.Size = UDim2.new(1, -28, 0, 1)
    h.Position = UDim2.fromOffset(14, 255)
    h.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
    h.BorderSizePixel = 0

    local i = Instance.new("TextLabel", br.Sidebar)
    i.Size = UDim2.new(1, -28, 0, 14)
    i.Position = UDim2.fromOffset(14, 270)
    i.BackgroundTransparency = 1
    i.Text = "QUICK TOOLS"
    i.Font = Enum.Font.GothamBold
    i.TextSize = 10
    i.TextColor3 = Color3.fromRGB(140, 125, 165)
    i.TextXAlignment = Enum.TextXAlignment.Left

    local d = Instance.new("TextButton", br.Sidebar)
    d.Size = UDim2.new(1, -28, 0, 36)
    d.Position = UDim2.fromOffset(14, 292)
    d.BackgroundColor3 = Color3.fromRGB(26, 18, 38)
    d.Text = ""
    d.ClipsDescendants = false
    Instance.new("UICorner", d).CornerRadius = UDim.new(0, 8)

    local e = Instance.new("UIStroke", d)
    e.Color = Color3.fromRGB(157, 78, 221)
    e.Transparency = 0.5
    e.Thickness = 1.2

    local f = Instance.new("ImageLabel", d)
    f.Size = UDim2.fromOffset(16, 16)
    f.Position = UDim2.new(0, 14, 0.5, -8)
    f.BackgroundTransparency = 1
    f.Image = ag.REFRESH
    f.ImageColor3 = Color3.fromRGB(210, 150, 255)

    local g = Instance.new("TextLabel", d)
    g.Size = UDim2.new(1, -44, 1, 0)
    g.Position = UDim2.fromOffset(40, 0)
    g.BackgroundTransparency = 1
    g.Text = "Rescan Assets"
    g.Font = Enum.Font.GothamBold
    g.TextSize = 11
    g.TextColor3 = Color3.fromRGB(230, 220, 250)
    g.TextXAlignment = Enum.TextXAlignment.Left

    br.RescanBtn = d
    br.scanLbl = g

    d.MouseEnter:Connect(function()
        ae:Create(d, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(157, 78, 221)}):Play()
        ae:Create(e, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = 0}):Play()
        ae:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.new(1, 1, 1)}):Play()
        ae:Create(g, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.new(1, 1, 1)}):Play()
    end)
    d.MouseLeave:Connect(function()
        ae:Create(d, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(26, 18, 38)}):Play()
        ae:Create(e, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = 0.5}):Play()
        ae:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(210, 150, 255)}):Play()
        ae:Create(g, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(230, 220, 250)}):Play()
    end)
    d.MouseButton1Down:Connect(function()
        ae:Create(d, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120, 50, 180)}):Play()
    end)
    d.MouseButton1Up:Connect(function()
        ae:Create(d, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(157, 78, 221)}):Play()
        ae:Create(f, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = f.Rotation + 360}):Play()
    end)
end

local bv, bw, bx
local function transformValue12(a)
    local b
    local function onMouseEnter()
        ae:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(199, 125, 255)}):Play()
    end
    local function onMouseLeave()
        ae:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(157, 78, 221)}):Play()
    end
    local function onMouseButton1Click()
        if b.Text == "LOADING" then
            return
        end
        b.Text = "LOADING"
        b.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
        task.spawn(function()
            at.RenderStepped:Wait()
            task.wait(0.05)
            local ok, msg = false, "Importer belum terhubung"
            if type(bx) == "function" then
                ok, msg = bx(a)
            end
            if ok then
                b.Text = "DONE"
                b.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                if bu then
                    bu("Success", tostring(msg or "Asset dimuat."), false)
                end
            else
                b.Text = "FAIL"
                b.BackgroundColor3 = Color3.fromRGB(230, 70, 90)
                if bu then
                    bu("Failed", tostring(msg or "Gagal memuat asset."), true)
                end
            end
            task.wait(2)
            if b and b.Parent then
                b.Text = "IMPORT"
                b.BackgroundColor3 = Color3.fromRGB(157, 78, 221)
            end
        end)
    end

    local scroll = br.Scroll
    local c = Instance.new("Frame", scroll)
    c.Size = UDim2.new(1, 0, 0, 56)
    c.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)

    local d = Instance.new("UIStroke", c)
    d.Color = Color3.fromRGB(50, 40, 70)
    d.Transparency = 0.5
    c:SetAttribute("FileType", a.ftype)

    local currentFilter = _G.CurrentFileFilter or "ALL"
    local e = (a.ftype == "RBXM" or a.ftype == "RBXMX") and "MODEL" or "PLACE"
    c.Visible = currentFilter == "ALL" or e == currentFilter

    local f = a.ftype == "RBXL" or a.ftype == "RBXLX"
    local g = f and Color3.fromRGB(199, 125, 255) or Color3.fromRGB(80, 180, 120)

    local h = Instance.new("Frame", c)
    h.Size = UDim2.fromOffset(36, 36)
    h.Position = UDim2.fromOffset(12, 10)
    h.BackgroundColor3 = g
    h.BackgroundTransparency = 0.85
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 8)

    local imageLabel4 = Instance.new("ImageLabel", h)
    imageLabel4.Size = UDim2.fromOffset(18, 18)
    imageLabel4.Position = UDim2.fromScale(0.5, 0.5)
    imageLabel4.AnchorPoint = Vector2.new(0.5, 0.5)
    imageLabel4.BackgroundTransparency = 1
    imageLabel4.Image = f and ag.GAMEPAD or ag.FILE
    imageLabel4.ImageColor3 = g

    local i = Instance.new("TextLabel", c)
    i.Size = UDim2.new(1, -135, 0, 18)
    i.Position = UDim2.fromOffset(60, 10)
    i.BackgroundTransparency = 1
    i.Text = a.name
    i.Font = Enum.Font.GothamBold
    i.TextSize = 12
    i.TextColor3 = Color3.fromRGB(245, 240, 255)
    i.TextXAlignment = Enum.TextXAlignment.Left
    i.TextTruncate = Enum.TextTruncate.AtEnd

    local j = Instance.new("TextLabel", c)
    j.Size = UDim2.new(1, -135, 0, 16)
    j.Position = UDim2.fromOffset(60, 26)
    j.BackgroundTransparency = 1
    j.Text = a.path
    j.Font = Enum.Font.Gotham
    j.TextSize = 10
    j.TextColor3 = Color3.fromRGB(150, 140, 175)
    j.TextXAlignment = Enum.TextXAlignment.Left
    j.TextTruncate = Enum.TextTruncate.AtEnd

    local k = Instance.new("Frame", c)
    k.Size = UDim2.fromOffset(45, 14)
    k.Position = UDim2.fromOffset(60, 41)
    k.BackgroundColor3 = g
    k.BorderSizePixel = 0
    k.BackgroundTransparency = 0.15
    Instance.new("UICorner", k).CornerRadius = UDim.new(0, 4)

    local l = Instance.new("TextLabel", k)
    l.Size = UDim2.fromScale(1, 1)
    l.BackgroundTransparency = 1
    l.Text = a.ftype
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.TextColor3 = Color3.fromRGB(20, 15, 30)

    b = Instance.new("TextButton", c)
    b.Size = UDim2.fromOffset(65, 28)
    b.Position = UDim2.new(1, -77, 0.5, -14)
    b.BackgroundColor3 = Color3.fromRGB(157, 78, 221)
    b.Text = "IMPORT"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseEnter:Connect(onMouseEnter)
    b.MouseLeave:Connect(onMouseLeave)
    b.MouseButton1Click:Connect(onMouseButton1Click)
end

local by, bz, ca
local function onMouseButton1Click9()
    local function backgroundTask()
        at.RenderStepped:Wait()
        local toDestroy = {}
        for _, child in ipairs(br.Scroll:GetChildren()) do
            if child:IsA("Frame") then
                table.insert(toDestroy, child)
            end
        end
        local lastClock = os.clock()
        for _, item in ipairs(toDestroy) do
            item:Destroy()
            if os.clock() - lastClock > 0.015 then
                at.RenderStepped:Wait()
                lastClock = os.clock()
            end
        end

        local found = type(by) == "function" and by() or {}
        lastClock = os.clock()
        for _, asset in ipairs(found) do
            if type(bz) == "function" then
                bz(asset)
            end
            if os.clock() - lastClock > 0.015 then
                at.RenderStepped:Wait()
                lastClock = os.clock()
            end
        end

        br.lblFiles.Text = tostring(#found)
        br.lblRBXM.Text = tostring(#found)
        br.scanLbl.Text = "Rescan Assets"
        if #found > 0 then
            if bu then
                bu("Scan Complete", "Berhasil meload " .. #found .. " asset file.", false)
            end
        else
            if bu then
                bu("Empty", "Tidak ada file asset (RBXM/RBXL/XML) ditemukan.", true)
            end
        end
        task.wait(1)
        ca = false
    end
    if not ca then
        ca = true
        br.scanLbl.Text = "Scanning..."
        task.spawn(backgroundTask)
    end
end

local function backgroundTask11()
    if not hookmetamethod or not getnamecallmethod then
        return
    end
    pcall(function()
        hookmetamethod(game, "__namecall", function(self, ...)
            return self.__namecall and self:__namecall(...) or nil
        end)
    end)
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local playersService = game:GetService("Players")
al = playersService.LocalPlayer
while not al do
    task.wait(0.1)
    al = playersService.LocalPlayer
end

ae = game:GetService("TweenService")
game:GetService("ReplicatedStorage")
game:GetService("HttpService")
bs = game:GetService("UserInputService")
game:GetService("InsertService")
at = game:GetService("RunService")

af = gethui and gethui() or nil
if not af then
    local okGui, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    af = okGui and coreGui or al:WaitForChild("PlayerGui")
end

local rawSources = _G.FORKT_RAW_SOURCES
if not rawSources then
    rawSources = {}
    _G.FORKT_RAW_SOURCES = rawSources
end

ag = {
    PACKAGE = "rbxassetid://128864012857079",
    SEARCH = "rbxassetid://118685771787843",
    CLOSE = "rbxassetid://126290678159164",
    MINIMIZE = "rbxassetid://5107170187",
    CHEVRON_RIGHT = "rbxassetid://91989851273706",
    CHEVRON_LEFT = "rbxassetid://4940236840",
    BELL = "rbxassetid://14013788454",
    GAMEPAD = "rbxassetid://115836418226834",
    FILE = "rbxassetid://17109896197",
    DOWNLOAD = "rbxassetid://123012623525091",
    CHECK = "rbxassetid://18349889388",
    ALERT = "rbxassetid://7634887649",
    FOLDER = "rbxassetid://88761476236687",
    REFRESH = "rbxassetid://13492317101",
    SETTINGS = "rbxassetid://11956055886",
    DASHBOARD = "rbxassetid://90838150633173",
}

ab = {
    name = "Unknown",
    version = "Unknown",
    request = request or http_request,
    httpget = httpget,
    setclipboard = setclipboard or toclipboard,
    makefolder = makefolder,
    isfolder = isfolder,
    isfile = isfile,
    readfile = readfile,
    writefile = writefile,
    getcustomasset = getcustomasset,
    lz4compress = lz4compress,
    lz4decompress = lz4decompress,
    zstdcompress = zstdcompress,
    zstddecompress = zstddecompress,
    getfunctionbytecode = getfunctionbytecode,
    dumpbytecode = dumpbytecode,
    decompile = decompile,
    getscriptbytecode = getscriptbytecode,
}
pcall(tryOperation16)

bu = computeValue3
bw = createScreenGui
bt = runProtected4
ar = computeValue4
ap = transformValue5
aq = transformValue6

as = {
    String = StringHandler,
    Int32 = Int32Handler,
    Int64 = Int64Handler,
    Float32 = Float32Handler,
    Float64 = Float64Handler,
    InterleaveArrayWithSize = InterleaveArrayWithSizeHandler,
    Int32Array = Int32ArrayHandler,
    RbxF32Array = RbxF32ArrayHandler,
    RefArray = RefArrayHandler,
}

au = runProtected5
av = runProtected6
bf = runProtected9
az = extractDigits
ax = {}
ay = checkCondition5
bb = runProtected11
ba = transformValue7
bc = runProtected12
bd = runProtected13
bg = computeValue5
bh = function(path)
    if type(ab.readfile) == "function" then
        local ok, data = pcall(ab.readfile, path)
        if ok then
            return data
        end
    end
    return nil
end
bi = computeValue6
be = transformValue9
bj = runProtected15
bx = runProtected16
bl = runProtected17
bk = transformValue10
bm = transformValue11
bn = checkCondition6

bq = {
    "",
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "Download",
    "Downloads",
    "../Download",
    "../../Download",
    "Android/Download",
    "/sdcard/Download",
    "/sdcard/Downloads",
    "/sdcard/Delta/workspace",
    "/sdcard/Android/Delta/workspace",
    "/storage/emulated/0/Download",
    "/storage/emulated/0/Downloads",
    "../workspace",
    ".",
}
bo = 0
bp = processItems5
by = processItems6
br = {}
bz = transformValue12
ca = false

createScreenGui2()
getValue4()
connectEvents2()
computeValue7()
connectEvents3()
updateState10()
connectEvents4()
connectEvents5()

if br.RescanBtn then
    br.RescanBtn.MouseButton1Click:Connect(onMouseButton1Click9)
end
task.spawn(backgroundTask11)
