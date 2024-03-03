#[=======================================================================[.rst:
Papyrus
-------

Compile Papyrus scripts

Usage:

.. code-block:: cmake

  Papyrus_Add(<target> GAME <game_path>
              [MODE <Skyrim|SkyrimSE|Fallout4>]
              IMPORTS <import> ...
              SOURCES <source> ...
              [FLAGS <flags>]
              [COMPONENT] <component>
              [OPTIMIZE] [RELEASE] [FINAL] [VERBOSE] [ANONYMIZE]
              [SKIP_DEFAULT_IMPORTS])

Using this command will populate the variable ``<target>_OUTPUT`` with the
files that will be generated by the Papyrus compiler.

Example:

.. code-block:: cmake

  Papyrus_Add("Papyrus"
              GAME $ENV{Skyrim64Path}
              IMPORTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts
                      $ENV{SKSE64Path}/Scripts/Source
              SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/scripts/MOD_Script1.psc
                      ${CMAKE_CURRENT_SOURCE_DIR}/scripts/MOD_Script2.psc
              OPTIMIZE ANONYMIZE)

  Papyrus_Add("Papyrus"
              GAME $ENV{Fallout4Path}
              MODE Fallout4
              IMPORTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts
              SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/scripts/MOD_Script1.psc
                      ${CMAKE_CURRENT_SOURCE_DIR}/scripts/MOD_Script2.psc
              OPTIMIZE RELEASE FINAL)
#]=======================================================================]

macro(Papyrus_FindCaprica)
	find_program(PAPYRUS_COMPILER "Caprica" PATHS "tools/Caprica" NO_CACHE)

	if(NOT PAPYRUS_COMPILER)
		set(CAPRICA_DOWNLOAD "${CMAKE_CURRENT_BINARY_DIR}/download/Caprica.v0.3.0.7z")

		file(DOWNLOAD
			"https://github.com/Orvid/Caprica/releases/download/v0.3.0/Caprica.v0.3.0.7z"
			"${CAPRICA_DOWNLOAD}"
			EXPECTED_HASH SHA3_224=4224c861424e8e4dc20ffc45cc605200035f897771af158c1459c021
			STATUS CAPRICA_STATUS
		)

		list(GET CAPRICA_STATUS 0 CAPRICA_ERROR_CODE)
		if(CAPRICA_ERROR_CODE)
			list(GET CAPRICA_STATUS 1 CAPRICA_ERROR_MESSAGE)
			message(FATAL_ERROR "${CAPRICA_ERROR_MESSAGE}")
		endif()

		file(ARCHIVE_EXTRACT
			INPUT "${CAPRICA_DOWNLOAD}"
			DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/tools/Caprica"
		)

		set(PAPYRUS_COMPILER "${CMAKE_CURRENT_BINARY_DIR}/tools/Caprica/Caprica.exe")
	endif()
endmacro()

macro(Papyrus_FindPexAnon)
	find_program(PEXANON_COMMAND "AFKPexAnon" PATHS "tools/AFKPexAnon" NO_CACHE)

	if(NOT PEXANON_COMMAND)
		set(PEXANON_DOWNLOAD "${CMAKE_CURRENT_BINARY_DIR}/download/AFKPexAnon-1.1.0-x64.7z")

		file(DOWNLOAD
			"https://github.com/namralkeeg/AFKPexAnon/releases/download/v1.1.0/AFKPexAnon-1.1.0-x64.7z"
			"${PEXANON_DOWNLOAD}"
			EXPECTED_HASH SHA3_224=48721850d462232f2b0e3da91055fbb014b88590a50dac36965c1143
			STATUS PEXANON_STATUS
		)

		list(GET PEXANON_STATUS 0 PEXANON_ERROR_CODE)
		if(PEXANON_ERROR_CODE)
			list(GET PEXANON_STATUS 1 PEXANON_ERROR_MESSAGE)
			message(FATAL_ERROR "${PEXANON_ERROR_MESSAGE}")
		endif()

		file(ARCHIVE_EXTRACT
			INPUT "${PEXANON_DOWNLOAD}"
			DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/tools/AFKPexAnon"
		)

		set(PEXANON_COMMAND "${CMAKE_CURRENT_BINARY_DIR}/tools/AFKPexAnon/AFKPexAnon.exe")
	endif()
endmacro()

function(Papyrus_Add PAPYRUS_TARGET)
	set(options OPTIMIZE RELEASE FINAL VERBOSE ANONYMIZE SKIP_DEFAULT_IMPORTS)
	set(oneValueArgs GAME MODE FLAGS COMPONENT)
	set(multiValueArgs IMPORTS SOURCES)
	cmake_parse_arguments(PAPYRUS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	if(PAPYRUS_MODE STREQUAL "Skyrim" OR EXISTS "${PAPYRUS_GAME}/TESV.exe")
		set(IS_SKYRIM TRUE)
	elseif(PAPYRUS_MODE STREQUAL "SkyrimSE" OR EXISTS "${PAPYRUS_GAME}/SkyrimSE.exe")
		set(IS_SKYRIMSE TRUE)
	elseif(PAPYRUS_MODE STREQUAL "Fallout4" OR EXISTS "${PAPYRUS_GAME}/Fallout4.exe")
		set(IS_FALLOUT4 TRUE)
	elseif(PAPYRUS_MODE STREQUAL "Fallout76")
		set(IS_FALLOUT76 TRUE)
	elseif(PAPYRUS_MODE STREQUAL "Starfield")
		set(IS_STARFIELD TRUE)
	else()
		message(FATAL_ERROR "Invalid Papyrus_Add mode specified.")
	endif()

	set(QUOTE_LITERAL [=["]=])
	list(APPEND PAPYRUS_IMPORT_DIR "${PAPYRUS_IMPORTS}")
	if(PAPYRUS_GAME AND NOT PAPYRUS_SKIP_DEFAULT_IMPORTS)
		if(IS_SKYRIM)
			list(APPEND PAPYRUS_IMPORT_DIR "${PAPYRUS_GAME}/Data/Scripts/Source")
		elseif(IS_SKYRIMSE)
			list(APPEND PAPYRUS_IMPORT_DIR "${PAPYRUS_GAME}/Data/Source/Scripts")
		elseif(IS_FALLOUT4)
			list(APPEND PAPYRUS_IMPORT_DIR
				"${PAPYRUS_GAME}/Data/Scripts/Source/User"
				"${PAPYRUS_GAME}/Data/Scripts/Source/CreationClub"
				"${PAPYRUS_GAME}/Data/Scripts/Source/DLC06"
				"${PAPYRUS_GAME}/Data/Scripts/Source/DLC05"
				"${PAPYRUS_GAME}/Data/Scripts/Source/DLC04"
				"${PAPYRUS_GAME}/Data/Scripts/Source/DLC03"
				"${PAPYRUS_GAME}/Data/Scripts/Source/DLC02"
				"${PAPYRUS_GAME}/Data/Scripts/Source/DLC01"
				"${PAPYRUS_GAME}/Data/Scripts/Source/Base"
			)
		endif()
	endif()
	string(APPEND PAPYRUS_IMPORT_ARG ${QUOTE_LITERAL} "${PAPYRUS_IMPORT_DIR}" ${QUOTE_LITERAL})

	set(PAPYRUS_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/Scripts")
	string(APPEND PAPYRUS_OUTPUT_ARG ${QUOTE_LITERAL} "${PAPYRUS_OUTPUT_DIR}" ${QUOTE_LITERAL})

	if(PAPYRUS_FLAGS)
		string(APPEND PAPYRUS_FLAGS_ARG ${QUOTE_LITERAL} "${PAPYRUS_FLAGS}" ${QUOTE_LITERAL})
	else()
		if(IS_SKYRIM OR IS_SKYRIMSE)
			string(APPEND PAPYRUS_FLAGS_ARG ${QUOTE_LITERAL} "TESV_Papyrus_Flags.flg" ${QUOTE_LITERAL})
		elseif(IS_FALLOUT4)
			string(APPEND PAPYRUS_FLAGS_ARG ${QUOTE_LITERAL} "Institute_Papyrus_Flags.flg" ${QUOTE_LITERAL})
		endif()
	endif()

	if(PAPYRUS_GAME)
		set(PAPYRUS_COMPILER "${PAPYRUS_GAME}/Papyrus Compiler/PapyrusCompiler.exe")

		string(
			APPEND
			PAPYRUS_COMPILER_ARGS
			"-import=${PAPYRUS_IMPORT_ARG} -output=${PAPYRUS_OUTPUT_ARG} -flags=${PAPYRUS_FLAGS_ARG}")

		if(PAPYRUS_FINAL)
			if(IS_FALLOUT4)
				string(APPEND PAPYRUS_COMPILER_ARGS " -optimize -release -final")
			else()
				string(APPEND PAPYRUS_COMPILER_ARGS " -optimize")
			endif()
		elseif(PAPYRUS_RELEASE)
			if(IS_FALLOUT4)
				string(APPEND PAPYRUS_COMPILER_ARGS " -optimize -release")
			else()
				string(APPEND PAPYRUS_COMPILER_ARGS " -optimize")
			endif()
		elseif(PAPYRUS_OPTIMIZE)
			string(APPEND PAPYRUS_COMPILER_ARGS " -optimize")
		endif()

		if(NOT PAPYRUS_VERBOSE)
			string(APPEND PAPYRUS_COMPILER_ARGS " -quiet")
		endif()
	else()
		Papyrus_FindCaprica()

		if(IS_SKYRIM OR IS_SKYRIMSE)
			string(
				APPEND
				PAPYRUS_COMPILER_ARGS
				"--game=skyrim"
			)
		elseif(IS_FALLOUT4)
			string(
				APPEND
				PAPYRUS_COMPILER_ARGS
				"--game=fallout4"
			)
		elseif(IS_FALLOUT76)
			string(
				APPEND
				PAPYRUS_COMPILER_ARGS
				"--game=fallout76"
			)
		elseif(IS_STARFIELD)
			string(
				APPEND
				PAPYRUS_COMPILER_ARGS
				"--game=starfield"
			)
		endif()

		string(
			APPEND
			PAPYRUS_COMPILER_ARGS
			" --import=${PAPYRUS_IMPORT_ARG} --output=${PAPYRUS_OUTPUT_ARG} --flags=${PAPYRUS_FLAGS_ARG}")

		if(PAPYRUS_FINAL)
			string(APPEND PAPYRUS_COMPILER_ARGS " --optimize --release --final")
		elseif(PAPYRUS_RELEASE)
			string(APPEND PAPYRUS_COMPILER_ARGS " --optimize")
		elseif(PAPYRUS_OPTIMIZE)
			string(APPEND PAPYRUS_COMPILER_ARGS " --optimize")
		endif()

		if(NOT PAPYRUS_VERBOSE)
			string(APPEND PAPYRUS_COMPILER_ARGS " --quiet")
		endif()
	endif()

	foreach(SOURCE IN ITEMS ${PAPYRUS_SOURCES})
		cmake_path(GET SOURCE STEM LAST_ONLY SOURCE_FILENAME)
		cmake_path(REPLACE_EXTENSION SOURCE_FILENAME LAST_ONLY "pex" OUTPUT_VARIABLE OUTPUT_FILENAME)
		cmake_path(APPEND PAPYRUS_OUTPUT_DIR "${OUTPUT_FILENAME}" OUTPUT_VARIABLE OUTPUT_FILE)
		list(APPEND PAPYRUS_OUTPUT "${OUTPUT_FILE}")

		add_custom_command(
			OUTPUT "${OUTPUT_FILE}"
			COMMAND "${PAPYRUS_COMPILER}"
				"${SOURCE}"
				"${PAPYRUS_COMPILER_ARGS}"
			DEPENDS "${SOURCE}"
		)
	endforeach()

	set(_DUMMY "${CMAKE_CURRENT_BINARY_DIR}/_Papyrus/${PAPYRUS_TARGET}.stamp")
	add_custom_command(
		OUTPUT "${_DUMMY}"
		DEPENDS ${PAPYRUS_OUTPUT}
		COMMAND "${CMAKE_COMMAND}" -E touch "${_DUMMY}"
		VERBATIM
	)

	if(PAPYRUS_ANONYMIZE)
		Papyrus_FindPexAnon()

		add_custom_command(
			OUTPUT "${_DUMMY}"
			COMMAND "${PEXANON_COMMAND}" -s "${PAPYRUS_OUTPUT_DIR}"
			COMMAND "${CMAKE_COMMAND}" -E touch "${_DUMMY}"
			VERBATIM
			APPEND
		)
	endif()

	add_custom_target(
		"${PAPYRUS_TARGET}"
		ALL
		DEPENDS "${_DUMMY}"
		SOURCES ${PAPYRUS_SOURCES}
	)

	set("${PAPYRUS_TARGET}_OUTPUT" ${PAPYRUS_OUTPUT} PARENT_SCOPE)

	source_group("Scripts" FILES ${PAPYRUS_SOURCES})

	if(PAPYRUS_COMPONENT)
		install(
			FILES ${PAPYRUS_OUTPUT}
			DESTINATION "Scripts"
			COMPONENT ${PAPYRUS_COMPONENT}
		)

		install(
			FILES ${PAPYRUS_SOURCES}
			DESTINATION $<IF:$<BOOL:IS_SKYRIMSE>,Source/Scripts,Scripts/Source>
			COMPONENT ${PAPYRUS_COMPONENT}
		)
	endif()

endfunction()
