#[=======================================================================[.rst:
BSArchive
---------

Create BSA (Bethesda Games Studios Archive) files

Usage:

..

  bethesda_archive(<target> OUTPUT <file>
                   FORMAT <TES3|TES4|FO3|FNV|TES5|SSE|FO4|FO4DDS>
                   FILES <file> [...]
                   [PREFIX <prefix>]
                   [ARCHIVE_FLAGS <value>]
                   [FILE_FLAGS <value>]
                   [COMPRESS] [SHARE])

Example:

.. code-block:: cmake

  set(Papyrus_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Scripts/MOD_Script1.pex
                     ${CMAKE_CURRENT_BINARY_DIR}/Scripts/MOD_Script2.pex)

  bethesda_archive("BSA" OUTPUT "MyMod.bsa"
                   FORMAT SSE
                   FILES ${Papyrus_OUTPUT})
#]=======================================================================]

function(bethesda_archive BSARCHIVE_TARGET)
	set(options COMPRESS SHARE)
	set(oneValueArgs OUTPUT FORMAT ARCHIVE_FLAGS FILE_FLAGS)
	set(multiValueArgs PREFIX FILES)
	cmake_parse_arguments(BSARCHIVE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	cmake_path(ABSOLUTE_PATH BSARCHIVE_OUTPUT BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
	list(APPEND BSARCHIVE_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}")
	list(REMOVE_DUPLICATES BSARCHIVE_PREFIX)

	find_program(BSARCH_PATH bsarch "tools")

	if(NOT BSARCH_PATH)
		file(
			DOWNLOAD
			"https://github.com/TES5Edit/TES5Edit/raw/b3235062f275a7d4a94162af910923ba79f0e77a/Tools/BSArchive/bsarch.exe"
			"${CMAKE_CURRENT_BINARY_DIR}/tools/bsarch.exe"
		)

		set(BSARCH_PATH "${CMAKE_CURRENT_BINARY_DIR}/tools/bsarch.exe")
	endif()

	set(BSARCHIVE_TEMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/temp_bsarch")

	foreach(INPUT_FILE IN ITEMS ${BSARCHIVE_FILES})
		cmake_path(GET INPUT_FILE RELATIVE_PART ARCHIVE_PATH)

		foreach(PREFIX IN ITEMS ${BSARCHIVE_PREFIX})
			cmake_path(IS_PREFIX PREFIX "${INPUT_FILE}" NORMALIZE IN_PREFIX_PATH)
			if(IN_PREFIX_PATH)
				cmake_path(
					RELATIVE_PATH
					INPUT_FILE
					BASE_DIRECTORY "${PREFIX}"
					OUTPUT_VARIABLE ARCHIVE_PATH
				)
				break()
			endif()
		endforeach()

		cmake_path(
			APPEND
			BSARCHIVE_TEMP_DIR "${ARCHIVE_PATH}"
			OUTPUT_VARIABLE OUTPUT_FILE
		)

		add_custom_command(
			OUTPUT "${OUTPUT_FILE}"
			COMMAND "${CMAKE_COMMAND}" -E copy_if_different
				"${INPUT_FILE}" "${OUTPUT_FILE}"
			DEPENDS "${INPUT_FILE}"
			VERBATIM
		)

		list(APPEND TEMP_FILES "${OUTPUT_FILE}")
	endforeach()

	add_custom_command(
		OUTPUT "${BSARCHIVE_OUTPUT}"
		COMMAND "${BSARCH_PATH}" pack
			"${BSARCHIVE_TEMP_DIR}"
			"${BSARCHIVE_OUTPUT}"
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,TES3>:-tes3>
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,TES4>:-tes4>
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,FO3>:-fo3>
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,FNV>:-fnv>
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,TES5>:-tes5>
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,SSE>:-sse>
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,FO4>:-fo4>
			$<$<STREQUAL:$<UPPER_CASE:${BSARCHIVE_FORMAT}>,FO4DDS>:-fo4dds>
			$<$<BOOL:${BSARCHIVE_ARCHIVE_FLAGS}>:-af:${ARCHIVE_FLAGS}>
			$<$<BOOL:${BSARCHIVE_FILE_FLAGS}>:-ff:${FILE_FLAGS}>
			$<$<BOOL:${BSARCHIVE_COMPRESS}>:-z>
			$<$<BOOL:${BSARCHIVE_SHARE}>:-share>
			-mt
		DEPENDS ${TEMP_FILES}
		VERBATIM
	)

	add_custom_target(
		"${BSARCHIVE_TARGET}" ALL
		DEPENDS "${BSARCHIVE_OUTPUT}"
	)
endfunction()