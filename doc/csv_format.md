# CSV Export Format Specification

## File Encoding

- **Encoding**: UTF-8 (with BOM)
- **Delimiter**: Comma (`,`)
- **Line Ending**: CRLF (`\r\n`)
- **Text Qualifier**: Double quote (`"`), used when field contains special characters

## File Naming Convention

Exported files follow this naming pattern:

```
recordings_YYYY-MM-DDTHH-MM-SS.ssssss.csv
```

Example: `recordings_2024-01-15T09-30-25.123456.csv`

## File Structure

The CSV file consists of two sections:

1. **Project Information** (at the top)
2. **Recording Entries** (below)

---

## Section 1: Project Information

This section appears at the beginning of the file and contains project metadata.

| Row | Column A | Column B | Example |
|-----|----------|----------|---------|
| 1 | `Project Information` | | (section header) |
| 2 | `Project Name` | Project name value | `My Movie` |
| 3 | `Production Company` | Company name | `Studio Inc.` |
| 4 | `Sound Engineer` | Engineer name | `John Doe` |
| 5 | `Boom Operator` | Operator name | `Jane Smith` |
| 6 | `Equipment Model` | Equipment model | `Sound Devices 688` |
| 7 | `File Format` | Audio file format | `WAV` |
| 8 | `Frame Rate` | Project frame rate | `24.0` |
| 9 | `Project Date` | ISO 8601 date | `2024-01-15T00:00:00.000` |
| 10 | `Roll Number` | Roll identifier | `A001` |
| 11 | `Channel Count` | Number of channels | `8` |

> **Note**: If no project settings are configured, this section is omitted.

---

## Section 2: Recording Entries

### Header Row (Row 13, if project info exists)

| Column | Name | Data Type | Description | Example |
|--------|------|-----------|-------------|---------|
| 1 | `ID` | Integer | Unique record identifier | `1` |
| 2 | `File Name` | String | Recording file name | `REC_001` |
| 3 | `Start TC` | String | Start timecode | `01:00:00:00` |
| 4 | `Scene` | String | Scene number | `1` |
| 5 | `Shot` | String | Shot number | `2` |
| 6 | `Take` | String | Take number | `3` |
| 7 | `Discarded` | String | Discarded flag: `Yes` or `No` | `No` |
| 8 | `Notes` | String | User notes | `Airplane flew by` |
| 9 | `Created At` | String | ISO 8601 timestamp | `2024-01-15T09:30:25.123456` |
| 10-33 | `Track 1` ~ `Track 24` | String | Track names (24 columns) | `Dialog 1` |
| 34-57 | `Track 1 Enabled` ~ `Track 24 Enabled` | String | Track enabled: `Yes` or `No` | `Yes` |

### Total Columns: 57

---

## Special Character Handling

When a field contains any of the following characters, the entire field is wrapped in double quotes, and internal double quotes are escaped as two double quotes:

- Comma (`,`)
- Double quote (`"`)
- Newline (`\n`)
- Carriage return (`\r`)

### Example

Raw data: `Has "quotes" and, comma`

CSV encoded: `"Has ""quotes"" and, comma"`

---

## Data Example

```csv
Project Information
Project Name,My Movie
Production Company,Studio Inc.
Sound Engineer,John Doe
Boom Operator,Jane Smith
Equipment Model,Sound Devices 688
File Format,WAV
Frame Rate,24.0
Project Date,2024-01-15T00:00:00.000
Roll Number,A001
Channel Count,8

ID,File Name,Start TC,Scene,Shot,Take,Discarded,Notes,Created At,Track 1,Track 2,Track 3,...,Track 24,Track 1 Enabled,Track 2 Enabled,...,Track 24 Enabled
1,REC_001,01:00:00:00,1,1,1,No,Airplane flew by,2024-01-15T09:30:25.123456,Dialog 1,Dialog 2,,...,Dialog 24,Yes,Yes,...,No
2,REC_002,01:05:00:00,1,1,2,No,,2024-01-15T09:35:10.234567,Dialog 1,Dialog 2,,...,Dialog 24,Yes,Yes,...,No
3,REC_003,01:10:00:00,1,2,1,Yes,Clipping occurred,2024-01-15T09:40:15.345678,Dialog 1,,,...,Dialog 24,Yes,No,...,No
```

---

## Notes

1. **Empty Values**: Empty string fields are left blank without any content
2. **Track Count**: Fixed 24 tracks are exported regardless of actual channel count
3. **Discarded Records**: Discarded records are included in export; filter using the `Discarded` column
4. **Time Format**: Creation time uses ISO 8601 standard format for easy parsing
5. **Boolean Values**: Boolean fields use `Yes`/`No` instead of `true`/`false` for better compatibility
6. **File Location**: Files are saved to the user-selected directory

## Import Recommendations

To import CSV into other software (Excel, Numbers, Google Sheets):

1. Open the software and select import CSV
2. Choose UTF-8 encoding
3. Set delimiter to comma
4. Set text qualifier to double quote
5. The first 11 rows contain project info; data starts from row 13
