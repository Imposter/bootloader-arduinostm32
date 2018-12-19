--[[
    STM32 Arduino Bootloader (DFU)
    Based on works by Roger Clark, 
    Jonatan Olofsson and LeafLabs
--]]

_CHIPSET = "cortex-m3"
_TOOLCHAIN_PREFIX = "arm-none-eabi-"

function TOOLCHAIN_TOOL(name, args)
    if (args ~= nil) then
        return _TOOLCHAIN_PREFIX .. name .. " " .. args
    end
    return _TOOLCHAIN_PREFIX .. name
end

-- Utility
-- Override premake's escape function
function premake.esc(obj)
    if (type(obj) ~= "string") then
        return obj
    end

    local str = tostring(obj)
    str = str:gsub('\\', '\\\\')
    --str = str:gsub('"', '\\"')
    
	return str
end

-- Relative to Absolute
function _RA(p)
	return path.getabsolute(p)
end

function USB_STR(str)
    local res = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        res = res .. "'" .. c .. "',0,"
    end
    return res:sub(1, #res - 1)
end

-- Define USB options
newoption({
    trigger = "usbvendid",
    value = "Hex number",
    description = "Specify an alternative USB vendor ID"
})
newoption({
    trigger = "usbprodid",
    value = "Hex number",
    description = "Specify an alternative USB product ID"
})
newoption({
    trigger = "usbvendstr",
    value = "String",
    description = "Specify an alternative USB vendor string"
})
newoption({
    trigger = "usbprodstr",
    value = "String",
    description = "Specify an alternative USB product string"
})
newoption({
    trigger = "usbserialstr",
    value = "String",
    description = "Specify an alternative USB serial number"
})

-- Tested on Ubuntu LTS 16.04.1
workspace("bootloader-arduinostm32")
    location("build")
    configurations({ 
        "maple-mini", 
        "maple-rev3", 
        "maple-rev5", 
        "generic-pc13", 
        "generic-pg15", 
        "generic-pd2", 
        "generic-pd1", 
        "generic-pa1", 
        "generic-pa1-button-pa8", 
        "generic-pb9", 
        "generic-pe2", 
        "generic-pa9", 
        "generic-pe5", 
        "generic-pe5-button-pa0", 
        "generic-pb7", 
        "generic-pb0", 
        "stbee", 
        "naze32", 
        "generic-pb12", 
        "yhtiny-stm32f103t", 
        "dso138", 
        "gd32f1-generic-pc13", 
        "gd32f1-frankenmaple"
    })

    project("Bootloader")
        kind("ConsoleApp")
        language("C")
        toolset("gcc")
        gccprefix(_TOOLCHAIN_PREFIX)
        architecture("ARM")
        characterset("MBCS")
        targetname("bootloader")

        includedirs({
            _RA("src/"),
            _RA("src/stm32_lib/"),
            _RA("src/usb_lib/")
        })

        files({
            _RA("src/*.c"),
            _RA("src/stm32_lib/c_only_startup.s"),
            _RA("src/stm32_lib/cortexm3_macro.s"),
            _RA("src/usb_lib/*.c")
        })

        -- USB settings
        if (_OPTIONS["usbvendid"] ~= nil) then
            defines({ "USB_DEF_VENDOR_ID=" .. _OPTIONS["usbvendid"] })
        end
        if (_OPTIONS["usbprodid"] ~= nil) then
            defines({ "USB_DEF_PRODUCT_ID=" .. _OPTIONS["usbprodid"] })
        end
        if (_OPTIONS["usbrev"] ~= nil) then
            defines({ "USB_DEF_REVISION=" .. _OPTIONS["usbrev"] })
        end
        if (_OPTIONS["usbvendstr"] ~= nil) then
            defines({ 
                'USB_DEF_VENDOR_DESC="' .. USB_STR(_OPTIONS["usbvendstr"]) .. '"',
                "USB_DEF_VENDOR_DESC_LEN=" .. #_OPTIONS["usbvendstr"]
            })
        end
        if (_OPTIONS["usbprodstr"] ~= nil) then
            defines({ 
                "USB_DEF_PRODUCT_DESC=" .. USB_STR(_OPTIONS["usbprodstr"]) .. "\"",
                "USB_DEF_PRODUCT_DESC_LEN=" .. #_OPTIONS["usbprodstr"]
            })
        end
        if (_OPTIONS["usbserialstr"] ~= nil) then
            defines({ 
                "USB_DEF_SERIAL_DESC=" .. USB_STR(_OPTIONS["usbserialstr"]) .. "\"",
                "USB_DEF_SERIAL_DESC_LEN=" .. #_OPTIONS["usbserialstr"]
            })
        end

        filter("configurations:*")
            optimize("Size")
            buildoptions({
                "-g -mcpu=" .. _CHIPSET,

                "-ffunction-sections -fdata-sections",
                "-Wall -Wimplicit",
                "-Wcast-align",
                "-Wpointer-arith -Wswitch",
                "-Wredundant-decls -Wreturn-type -Wshadow -Wunused"
            })

            linkoptions({
                "-nostartfiles",
                "-Wl,--cref,--gc-sections",
                "-lc",
                "-lgcc" 
            })

            postbuildcommands({
                -- Generate files
                TOOLCHAIN_TOOL("objcopy", "-O ihex %{cfg.buildtarget.relpath} %{cfg.buildtarget.directory}/%{cfg.buildtarget.basename}.hex"),
                TOOLCHAIN_TOOL("objcopy", "-O binary %{cfg.buildtarget.relpath} %{cfg.buildtarget.directory}/%{cfg.buildtarget.basename}.bin"),
                TOOLCHAIN_TOOL("objdump", "-h -S -D %{cfg.buildtarget.relpath} > %{cfg.buildtarget.directory}/%{cfg.buildtarget.basename}.lss")                
            })

        -- TODO: Different header files for each target so we don't have to do this!
        filter("configurations:maple-mini")
            defines({ "TARGET_MAPLE_MINI" })
            linkoptions({ "-T" .. _RA("src/stm32_lib/c_only_md_high_density.ld") })
        
        filter("configurations:generic-pc13")
            defines({ "TARGET_GENERIC_F103_PC13" })
            linkoptions({ "-T" .. _RA("src/stm32_lib/c_only_md_high_density.ld") })

        