--[[
    STM32 Arduino Bootloader (DFU)
    Based on works by Roger Clark, 
    Jonatan Olofsson and LeafLabs
--]]

chipset = "cortex-m3"
toolchain_prefix = "arm-none-eabi-"

function toolchain_tool(name, args)
    if (args ~= nil) then
        return toolchain_prefix .. name .. " " .. args
    end
    return toolchain_prefix .. name
end

-- Utility
-- Relative to Absolute
function _RA(p)
	return path.getabsolute(p)
end

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
        gccprefix(toolchain_prefix)
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

        filter("configurations:*")
            optimize("Size")
            buildoptions({
                "-g -mcpu=" .. chipset,

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
                toolchain_tool("objcopy", "-O ihex %{cfg.buildtarget.relpath} %{cfg.buildtarget.directory}/%{cfg.buildtarget.basename}.hex"),
                toolchain_tool("objcopy", "-O binary %{cfg.buildtarget.relpath} %{cfg.buildtarget.directory}/%{cfg.buildtarget.basename}.bin"),
                toolchain_tool("objdump", "-h -S -D %{cfg.buildtarget.relpath} > %{cfg.buildtarget.directory}/%{cfg.buildtarget.basename}.lss")                
            })

        -- TODO: Different header files for each target so we don't have to do this!
        filter("configurations:maple-mini")
            defines({ "TARGET_MAPLE_MINI" })
            linkoptions({ "-T" .. _RA("src/stm32_lib/c_only_md_high_density.ld") })
        
        filter("configurations:generic-pc13")
            defines({ "TARGET_GENERIC_F103_PC13" })
            linkoptions({ "-T" .. _RA("src/stm32_lib/c_only_md_high_density.ld") })

        