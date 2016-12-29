RMSData = require '../../src/app/utils/RMSData'

describe '320 TaskSplitSaveData', ->

  # RMS Data (DO NOT CHANGE!) {.....} END

  it 'RMSData.get', ->

    example = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) {"a":12} END

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(data = RMSData.get example).not.toBeNull()
    expect(data).toEqual(a: 12)

    exampleNoEndText = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) {"a":12} END""".replace /\n/g, '\r\n'

    expect(data = RMSData.get exampleNoEndText).not.toBeNull()
    expect(data).toEqual(a: 12)

    exampleNoOtherText = "RMS Data (DO NOT CHANGE!) {\"a\":12} END".replace /\n/g, '\r\n'

    expect(data = RMSData.get exampleNoOtherText).not.toBeNull()
    expect(data).toEqual(a: 12)

    badExampleWrongJson = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) {a:12} END

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(RMSData.get badExampleWrongJson).toBeNull()

    badExampleNoJson = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) END

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(RMSData.get badExampleNoJson).toBeNull()

    badExampleJsonAfterEnd = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) END {"a":12}

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(RMSData.get badExampleJsonAfterEnd).toBeNull()

    badExampleEndMissing = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) END {"a":12}

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(RMSData.get badExampleEndMissing).toBeNull()

  it 'RMSData.put', ->

    example = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) {"a":12} END

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(RMSData.put example, {t:false}).toBe """
      Описание задачи
      Ещё что-то

      Продолжение

      RMS Data (DO NOT CHANGE!) {"t":false} END""".replace /\n/g, '\r\n'

    exampleEmptyDesc = ''
    expect(RMSData.put exampleEmptyDesc, {t:false}).toBe '\n\nRMS Data (DO NOT CHANGE!) {"t":false} END'.replace /\n/g, '\r\n'

    exampleRMSDataOnly = 'RMS Data (DO NOT CHANGE!) {} END'
    expect(RMSData.put exampleRMSDataOnly, {t:false}).toBe '\n\nRMS Data (DO NOT CHANGE!) {"t":false} END'.replace /\n/g, '\r\n'

    exampleNoDescNoData = ''
    expect(RMSData.put exampleNoDescNoData, null).toBe ''
    expect(RMSData.put exampleNoDescNoData, {}).toBe ''

    exampleNoEnd = """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) {"a":12}

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(RMSData.put exampleNoEnd, {t:false}).toBe """
      Описание задачи
      Ещё что-то

      RMS Data (DO NOT CHANGE!) {"t":false} END""".replace /\n/g, '\r\n'

    exampleTextAfterJson = """
      RMS Data (DO NOT CHANGE!) {"a":12}END


      Описание задачи
      Ещё что-то

      Продолжение
      """.replace /\n/g, '\r\n'

    expect(RMSData.put exampleTextAfterJson, {t:false}).toBe """
      Описание задачи
      Ещё что-то

      Продолжение

      RMS Data (DO NOT CHANGE!) {"t":false} END""".replace /\n/g, '\r\n'
