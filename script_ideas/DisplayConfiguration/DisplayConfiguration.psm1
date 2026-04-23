#Requires -Version 5.1

# ---------------------------------------------------------------------------
# DisplayConfiguration Module
# Uses the Win32 CCD (Connecting and Configuring Displays) API via P/Invoke
# to export and import display settings: resolution, scaling (DPI), position,
# primary display, rotation, and refresh rate.
# ---------------------------------------------------------------------------

#region P/Invoke Type Definitions

If (-not ('DisplayConfig.Native' -as [Type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace DisplayConfig
{
    // ---------------------------------------------------------------
    // Enums
    // ---------------------------------------------------------------

    [Flags]
    public enum QDC : uint
    {
        AllPaths           = 0x00000001,
        OnlyActivePaths    = 0x00000002,
        DatabaseCurrent    = 0x00000004,
        VirtualModeAware   = 0x00000010,
        IncludeHMD         = 0x00000020,
        VirtualRefreshRateAware = 0x00000040
    }

    [Flags]
    public enum SDC : uint
    {
        TopologyInternal       = 0x00000001,
        TopologyClone          = 0x00000002,
        TopologyExtend         = 0x00000004,
        TopologyExternal       = 0x00000008,
        TopologySupplied       = 0x00000010,
        UseSuppliedDisplayConfig = 0x00000020,
        Validate               = 0x00000040,
        Apply                  = 0x00000080,
        NoOptimization         = 0x00000100,
        SaveToDatabase         = 0x00000200,
        AllowChanges           = 0x00000400,
        PathPersistIfRequired  = 0x00000800,
        ForceModeEnumeration   = 0x00001000,
        AllowPathOrderChanges  = 0x00002000,
        VirtualModeAware       = 0x00008000,
        VirtualRefreshRateAware = 0x00020000
    }

    public enum DisplayConfigVideoOutputTechnology : uint
    {
        Other                = unchecked((uint)-1),
        HD15                 = 0,
        SVideo               = 1,
        CompositeVideo       = 2,
        ComponentVideo       = 3,
        DVI                  = 4,
        HDMI                 = 5,
        LVDS                 = 6,
        DJpn                 = 8,
        SDI                  = 9,
        DisplayPortExternal  = 10,
        DisplayPortEmbedded  = 11,
        UDIExternal          = 12,
        UDIEmbedded          = 13,
        SDTVDongle           = 14,
        Miracast             = 15,
        IndirectWired        = 16,
        IndirectVirtual      = 17,
        Internal             = 0x80000000
    }

    public enum DisplayConfigRotation : uint
    {
        Identity  = 1,
        Rotate90  = 2,
        Rotate180 = 3,
        Rotate270 = 4
    }

    public enum DisplayConfigScaling : uint
    {
        Identity               = 1,
        Centered               = 2,
        Stretched              = 3,
        AspectRatioCenteredMax = 4,
        Custom                 = 5,
        Preferred              = 128
    }

    public enum DisplayConfigScanLineOrdering : uint
    {
        Unspecified                = 0,
        Progressive                = 1,
        Interlaced                 = 2,
        InterlacedUpperFieldFirst  = Interlaced,
        InterlacedLowerFieldFirst  = 3
    }

    public enum DisplayConfigPixelFormat : uint
    {
        Bpp8    = 1,
        Bpp16   = 2,
        Bpp24   = 3,
        Bpp32   = 4,
        NonGDI  = 5
    }

    public enum DisplayConfigModeInfoType : uint
    {
        Source       = 1,
        Target       = 2,
        DesktopImage = 3
    }

    public enum DisplayConfigDeviceInfoType : uint
    {
        GetSourceName       = 1,
        GetTargetName       = 2,
        GetTargetPreferredMode = 3,
        GetAdapterName      = 4,
        SetTargetPersistence = 5,
        GetTargetBaseType   = 6,
        GetSupportVirtualResolution = 7,
        SetSupportVirtualResolution = 8,
        GetAdvancedColorInfo   = 9,
        SetAdvancedColorState  = 10,
        GetSDRWhiteLevel       = 11,
        // Undocumented DPI types
        GetDpiScale = unchecked((uint)(int)-3),
        SetDpiScale = unchecked((uint)(int)-4)
    }

    [Flags]
    public enum DisplayConfigSourceStatus : uint
    {
        InUse = 0x00000001
    }

    [Flags]
    public enum DisplayConfigTargetStatus : uint
    {
        InUse                  = 0x00000001,
        Forcible               = 0x00000002,
        ForcedAvailabilityBoot = 0x00000004,
        ForcedAvailabilityPath = 0x00000008,
        ForcedAvailabilitySystem = 0x00000010,
        IsHMD                  = 0x00000020,
    }

    [Flags]
    public enum DisplayConfigPathInfoFlags : uint
    {
        Active          = 0x00000001,
        PreferredUnscaled = 0x00000004,
        SupportVirtualResolution = 0x00000008
    }

    public enum DisplayConfigTopologyId : uint
    {
        Internal = 0x00000001,
        Clone    = 0x00000002,
        Extend   = 0x00000004,
        External = 0x00000008
    }

    // ---------------------------------------------------------------
    // Structures
    // ---------------------------------------------------------------

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID
    {
        public uint LowPart;
        public int  HighPart;

        public override bool Equals(object obj)
        {
            if (!(obj is LUID other)) return false;
            return LowPart == other.LowPart && HighPart == other.HighPart;
        }
        public override int GetHashCode() { return LowPart.GetHashCode() ^ HighPart.GetHashCode(); }
        public static bool operator ==(LUID a, LUID b) { return a.Equals(b); }
        public static bool operator !=(LUID a, LUID b) { return !a.Equals(b); }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINTL
    {
        public int x;
        public int y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigRational
    {
        public uint Numerator;
        public uint Denominator;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfig2DRegion
    {
        public uint cx;
        public uint cy;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigVideoSignalInfo
    {
        public ulong                       pixelRate;
        public DisplayConfigRational       hSyncFreq;
        public DisplayConfigRational       vSyncFreq;
        public DisplayConfig2DRegion       activeSize;
        public DisplayConfig2DRegion       totalSize;
        public uint                        videoStandard;
        public DisplayConfigScanLineOrdering scanLineOrdering;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigPathSourceInfo
    {
        public LUID   adapterId;
        public uint   id;
        public uint   modeInfoIdx;
        public DisplayConfigSourceStatus statusFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigPathTargetInfo
    {
        public LUID   adapterId;
        public uint   id;
        public uint   modeInfoIdx;
        public DisplayConfigVideoOutputTechnology outputTechnology;
        public DisplayConfigRotation              rotation;
        public DisplayConfigScaling               scaling;
        public DisplayConfigRational              refreshRate;
        public DisplayConfigScanLineOrdering      scanLineOrdering;
        public bool                               targetAvailable;
        public DisplayConfigTargetStatus          statusFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigPathInfo
    {
        public DisplayConfigPathSourceInfo sourceInfo;
        public DisplayConfigPathTargetInfo targetInfo;
        public DisplayConfigPathInfoFlags  flags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigSourceMode
    {
        public uint                  width;
        public uint                  height;
        public DisplayConfigPixelFormat pixelFormat;
        public POINTL                position;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigTargetMode
    {
        public DisplayConfigVideoSignalInfo targetVideoSignalInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigDesktopImageInfo
    {
        public POINTL PathSourceSize;
        public RECT   DesktopImageRegion;
        public RECT   DesktopImageClip;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int left;
        public int top;
        public int right;
        public int bottom;
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct DisplayConfigModeInfoUnion
    {
        [FieldOffset(0)] public DisplayConfigTargetMode       targetMode;
        [FieldOffset(0)] public DisplayConfigSourceMode       sourceMode;
        [FieldOffset(0)] public DisplayConfigDesktopImageInfo desktopImageInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigModeInfo
    {
        public DisplayConfigModeInfoType infoType;
        public uint                      id;
        public LUID                      adapterId;
        public DisplayConfigModeInfoUnion info;
    }

    // ---------------------------------------------------------------
    // Device-info request/response headers and structures
    // ---------------------------------------------------------------

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigDeviceInfoHeader
    {
        public DisplayConfigDeviceInfoType type;
        public uint size;
        public LUID adapterId;
        public uint id;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DisplayConfigTargetDeviceName
    {
        public DisplayConfigDeviceInfoHeader          header;
        public DisplayConfigTargetDeviceNameFlags      flags;
        public DisplayConfigVideoOutputTechnology      outputTechnology;
        public ushort                                  edidManufactureId;
        public ushort                                  edidProductCodeId;
        public uint                                    connectorInstance;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
        public string                                  monitorFriendlyDeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string                                  monitorDevicePath;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigTargetDeviceNameFlags
    {
        public uint value;
        public bool FriendlyNameFromEdid    { get { return (value & 0x1) != 0; } }
        public bool FriendlyNameForced      { get { return (value & 0x2) != 0; } }
        public bool EdidIdsValid            { get { return (value & 0x4) != 0; } }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DisplayConfigSourceDeviceName
    {
        public DisplayConfigDeviceInfoHeader header;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string viewGdiDeviceName;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DisplayConfigAdapterName
    {
        public DisplayConfigDeviceInfoHeader header;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string adapterDevicePath;
    }

    // Undocumented DPI-scale structures (types -3 / -4)
    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigGetDpiScale
    {
        public DisplayConfigDeviceInfoHeader header;
        public int minScaleRel;     // min relative scale steps
        public int curScaleRel;     // current relative scale step (0 = recommended)
        public int maxScaleRel;     // max relative scale steps
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigSetDpiScale
    {
        public DisplayConfigDeviceInfoHeader header;
        public int scaleRel;        // target relative scale step
    }

    // ---------------------------------------------------------------
    // P/Invoke function imports
    // ---------------------------------------------------------------

    public static class Native
    {
        [DllImport("user32.dll")]
        public static extern int GetDisplayConfigBufferSizes(
            QDC flags,
            out uint numPathArrayElements,
            out uint numModeInfoArrayElements
        );

        [DllImport("user32.dll")]
        public static extern int QueryDisplayConfig(
            QDC flags,
            ref uint numPathArrayElements,
            [Out] DisplayConfigPathInfo[] pathArray,
            ref uint numModeInfoArrayElements,
            [Out] DisplayConfigModeInfo[] modeInfoArray,
            out DisplayConfigTopologyId currentTopologyId
        );

        // Overload without topology (for QDC_ONLY_ACTIVE_PATHS which doesn't return one)
        [DllImport("user32.dll")]
        public static extern int QueryDisplayConfig(
            QDC flags,
            ref uint numPathArrayElements,
            [Out] DisplayConfigPathInfo[] pathArray,
            ref uint numModeInfoArrayElements,
            [Out] DisplayConfigModeInfo[] modeInfoArray,
            IntPtr currentTopologyId
        );

        [DllImport("user32.dll")]
        public static extern int SetDisplayConfig(
            uint numPathArrayElements,
            [In] DisplayConfigPathInfo[] pathArray,
            uint numModeInfoArrayElements,
            [In] DisplayConfigModeInfo[] modeInfoArray,
            SDC flags
        );

        [DllImport("user32.dll")]
        public static extern int DisplayConfigGetDeviceInfo(
            ref DisplayConfigTargetDeviceName requestPacket
        );

        [DllImport("user32.dll")]
        public static extern int DisplayConfigGetDeviceInfo(
            ref DisplayConfigSourceDeviceName requestPacket
        );

        [DllImport("user32.dll")]
        public static extern int DisplayConfigGetDeviceInfo(
            ref DisplayConfigAdapterName requestPacket
        );

        [DllImport("user32.dll")]
        public static extern int DisplayConfigGetDeviceInfo(
            ref DisplayConfigGetDpiScale requestPacket
        );

        [DllImport("user32.dll")]
        public static extern int DisplayConfigSetDeviceInfo(
            ref DisplayConfigSetDpiScale requestPacket
        );
    }

    // ---------------------------------------------------------------
    // Helpers — construct and mutate structs from PowerShell without
    // running into nested value-type copy semantics.
    // ---------------------------------------------------------------

    public static class Helpers
    {
        // -- Device-info request constructors --

        public static DisplayConfigTargetDeviceName NewTargetDeviceNameRequest(LUID adapterId, uint targetId)
        {
            var r = new DisplayConfigTargetDeviceName();
            r.header.type      = DisplayConfigDeviceInfoType.GetTargetName;
            r.header.size      = (uint)Marshal.SizeOf(typeof(DisplayConfigTargetDeviceName));
            r.header.adapterId = adapterId;
            r.header.id        = targetId;
            return r;
        }

        public static DisplayConfigSourceDeviceName NewSourceDeviceNameRequest(LUID adapterId, uint sourceId)
        {
            var r = new DisplayConfigSourceDeviceName();
            r.header.type      = DisplayConfigDeviceInfoType.GetSourceName;
            r.header.size      = (uint)Marshal.SizeOf(typeof(DisplayConfigSourceDeviceName));
            r.header.adapterId = adapterId;
            r.header.id        = sourceId;
            return r;
        }

        public static DisplayConfigGetDpiScale NewGetDpiScaleRequest(LUID adapterId, uint sourceId)
        {
            var r = new DisplayConfigGetDpiScale();
            r.header.type      = DisplayConfigDeviceInfoType.GetDpiScale;
            r.header.size      = (uint)Marshal.SizeOf(typeof(DisplayConfigGetDpiScale));
            r.header.adapterId = adapterId;
            r.header.id        = sourceId;
            return r;
        }

        public static DisplayConfigSetDpiScale NewSetDpiScaleRequest(LUID adapterId, uint sourceId, int scaleRel)
        {
            var r = new DisplayConfigSetDpiScale();
            r.header.type      = DisplayConfigDeviceInfoType.SetDpiScale;
            r.header.size      = (uint)Marshal.SizeOf(typeof(DisplayConfigSetDpiScale));
            r.header.adapterId = adapterId;
            r.header.id        = sourceId;
            r.scaleRel         = scaleRel;
            return r;
        }

        // -- Read nested fields from path arrays --

        public static LUID GetPathSourceAdapterId(DisplayConfigPathInfo[] paths, int index)  { return paths[index].sourceInfo.adapterId; }
        public static uint GetPathSourceId(DisplayConfigPathInfo[] paths, int index)         { return paths[index].sourceInfo.id; }
        public static uint GetPathSourceModeIdx(DisplayConfigPathInfo[] paths, int index)    { return paths[index].sourceInfo.modeInfoIdx; }
        public static LUID GetPathTargetAdapterId(DisplayConfigPathInfo[] paths, int index)  { return paths[index].targetInfo.adapterId; }
        public static uint GetPathTargetId(DisplayConfigPathInfo[] paths, int index)         { return paths[index].targetInfo.id; }
        public static uint GetPathTargetModeIdx(DisplayConfigPathInfo[] paths, int index)    { return paths[index].targetInfo.modeInfoIdx; }
        public static DisplayConfigRotation GetPathRotation(DisplayConfigPathInfo[] paths, int index) { return paths[index].targetInfo.rotation; }

        // -- Read nested fields from mode arrays --

        public static uint GetSourceModeWidth(DisplayConfigModeInfo[] modes, int index)          { return modes[index].info.sourceMode.width; }
        public static uint GetSourceModeHeight(DisplayConfigModeInfo[] modes, int index)         { return modes[index].info.sourceMode.height; }
        public static int  GetSourceModePositionX(DisplayConfigModeInfo[] modes, int index)      { return modes[index].info.sourceMode.position.x; }
        public static int  GetSourceModePositionY(DisplayConfigModeInfo[] modes, int index)      { return modes[index].info.sourceMode.position.y; }
        public static uint GetTargetModeVSyncNumerator(DisplayConfigModeInfo[] modes, int index)   { return modes[index].info.targetMode.targetVideoSignalInfo.vSyncFreq.Numerator; }
        public static uint GetTargetModeVSyncDenominator(DisplayConfigModeInfo[] modes, int index) { return modes[index].info.targetMode.targetVideoSignalInfo.vSyncFreq.Denominator; }
        public static DisplayConfigModeInfoType GetModeInfoType(DisplayConfigModeInfo[] modes, int index) { return modes[index].infoType; }

        // -- Mutate nested fields in mode arrays --

        public static void SetSourceModeResolution(DisplayConfigModeInfo[] modes, int index, uint width, uint height)
        {
            modes[index].info.sourceMode.width  = width;
            modes[index].info.sourceMode.height = height;
        }

        public static void SetSourceModePosition(DisplayConfigModeInfo[] modes, int index, int x, int y)
        {
            modes[index].info.sourceMode.position.x = x;
            modes[index].info.sourceMode.position.y = y;
        }

        public static void SetTargetModeActiveSize(DisplayConfigModeInfo[] modes, int index, uint cx, uint cy)
        {
            modes[index].info.targetMode.targetVideoSignalInfo.activeSize.cx = cx;
            modes[index].info.targetMode.targetVideoSignalInfo.activeSize.cy = cy;
        }

        public static void SetTargetModeRefreshRate(DisplayConfigModeInfo[] modes, int index, uint numerator, uint denominator)
        {
            modes[index].info.targetMode.targetVideoSignalInfo.vSyncFreq.Numerator   = numerator;
            modes[index].info.targetMode.targetVideoSignalInfo.vSyncFreq.Denominator = denominator;
        }

        // -- Mutate nested fields in path arrays --

        public static void SetPathRotation(DisplayConfigPathInfo[] paths, int index, DisplayConfigRotation rotation)
        {
            paths[index].targetInfo.rotation = rotation;
        }

        // -- Bulk operations --

        public static void OffsetAllSourcePositions(DisplayConfigModeInfo[] modes, int count, int offsetX, int offsetY)
        {
            for (int i = 0; i < count; i++)
            {
                if (modes[i].infoType == DisplayConfigModeInfoType.Source)
                {
                    modes[i].info.sourceMode.position.x -= offsetX;
                    modes[i].info.sourceMode.position.y -= offsetY;
                }
            }
        }

        // -- Path matching --

        public static bool PathMatches(DisplayConfigPathInfo[] paths, int index, LUID adapterId, uint sourceId, uint targetId)
        {
            return paths[index].sourceInfo.adapterId == adapterId
                && paths[index].sourceInfo.id == sourceId
                && paths[index].targetInfo.id == targetId;
        }
    }
}
'@ -ErrorAction Stop
}

#endregion P/Invoke Type Definitions

# ---------------------------------------------------------------------------
# DPI scale mapping: relative step index -> percentage.
# Step 0 = recommended (100% on most hardware).
# This table covers the known Windows scale percentages.
# ---------------------------------------------------------------------------
[int[]]$Script:DpiScalePercentage = @(100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500)

# ---------------------------------------------------------------------------
# The six configurable aspects (used by -Include / -Exclude parameters)
# ---------------------------------------------------------------------------
[string[]]$Script:ValidAspectList = @(
    'Resolution'
    'Scaling'
    'Position'
    'PrimaryDisplay'
    'Rotation'
    'RefreshRate'
)

#region Private Helpers

Function Get-ConnectedDisplay {
    <#
    .SYNOPSIS
        Queries the CCD API for all active (connected + in-use) displays.
    .OUTPUTS
        [PSCustomObject[]] One object per active display path.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    Param()

    # 1. Get buffer sizes
    [uint32]$pathCount = 0
    [uint32]$modeCount = 0
    [int]$hr = [DisplayConfig.Native]::GetDisplayConfigBufferSizes(
        [DisplayConfig.QDC]::OnlyActivePaths,
        [ref]$pathCount,
        [ref]$modeCount
    )
    If ($hr -ne 0) { Throw "GetDisplayConfigBufferSizes failed with HRESULT 0x$($hr.ToString('X8'))." }

    # 2. Query active paths
    [DisplayConfig.DisplayConfigPathInfo[]]$pathArray = New-Object 'DisplayConfig.DisplayConfigPathInfo[]' $pathCount
    [DisplayConfig.DisplayConfigModeInfo[]]$modeArray = New-Object 'DisplayConfig.DisplayConfigModeInfo[]' $modeCount
    $hr = [DisplayConfig.Native]::QueryDisplayConfig(
        [DisplayConfig.QDC]::OnlyActivePaths,
        [ref]$pathCount,
        $pathArray,
        [ref]$modeCount,
        $modeArray,
        [IntPtr]::Zero
    )
    If ($hr -ne 0) { Throw "QueryDisplayConfig failed with HRESULT 0x$($hr.ToString('X8'))." }

    # 3. Iterate each path and resolve device info
    [System.Collections.Generic.List[PSCustomObject]]$displayList = @()
    For ([int]$idx = 0; $idx -lt $pathCount; $idx++) {
        # -- Target device name (friendly name + device path) --
        [DisplayConfig.LUID]$tgtAdapterId = [DisplayConfig.Helpers]::GetPathTargetAdapterId($pathArray, $idx)
        [uint32]$tgtId = [DisplayConfig.Helpers]::GetPathTargetId($pathArray, $idx)
        [DisplayConfig.DisplayConfigTargetDeviceName]$targetName = [DisplayConfig.Helpers]::NewTargetDeviceNameRequest($tgtAdapterId, $tgtId)
        $hr = [DisplayConfig.Native]::DisplayConfigGetDeviceInfo([ref]$targetName)
        If ($hr -ne 0) { Continue }

        # -- Source device name (GDI name like \\.\DISPLAY1) --
        [DisplayConfig.LUID]$srcAdapterId = [DisplayConfig.Helpers]::GetPathSourceAdapterId($pathArray, $idx)
        [uint32]$srcId = [DisplayConfig.Helpers]::GetPathSourceId($pathArray, $idx)
        [DisplayConfig.DisplayConfigSourceDeviceName]$sourceName = [DisplayConfig.Helpers]::NewSourceDeviceNameRequest($srcAdapterId, $srcId)
        $hr = [DisplayConfig.Native]::DisplayConfigGetDeviceInfo([ref]$sourceName)
        If ($hr -ne 0) { Continue }

        # -- Resolve source and target mode info from the mode array --
        [uint32]$srcModeIdx = [DisplayConfig.Helpers]::GetPathSourceModeIdx($pathArray, $idx)
        [uint32]$tgtModeIdx = [DisplayConfig.Helpers]::GetPathTargetModeIdx($pathArray, $idx)

        [psobject]$resolutionObj = $null
        [psobject]$positionObj   = $null
        If ($srcModeIdx -lt $modeCount) {
            $resolutionObj = [PSCustomObject]@{
                Width  = [int][DisplayConfig.Helpers]::GetSourceModeWidth($modeArray, $srcModeIdx)
                Height = [int][DisplayConfig.Helpers]::GetSourceModeHeight($modeArray, $srcModeIdx)
            }
            $positionObj = [PSCustomObject]@{
                X = [DisplayConfig.Helpers]::GetSourceModePositionX($modeArray, $srcModeIdx)
                Y = [DisplayConfig.Helpers]::GetSourceModePositionY($modeArray, $srcModeIdx)
            }
        }

        [psobject]$refreshRateObj = $null
        If ($tgtModeIdx -lt $modeCount) {
            $refreshRateObj = [PSCustomObject]@{
                Numerator   = [int][DisplayConfig.Helpers]::GetTargetModeVSyncNumerator($modeArray, $tgtModeIdx)
                Denominator = [int][DisplayConfig.Helpers]::GetTargetModeVSyncDenominator($modeArray, $tgtModeIdx)
            }
        }

        # -- DPI scale (undocumented type -3) --
        [int]$dpiPercent = 100
        Try {
            [DisplayConfig.DisplayConfigGetDpiScale]$dpiGet = [DisplayConfig.Helpers]::NewGetDpiScaleRequest($srcAdapterId, $srcId)
            $hr = [DisplayConfig.Native]::DisplayConfigGetDeviceInfo([ref]$dpiGet)
            If ($hr -eq 0) {
                [int]$absIndex = $dpiGet.curScaleRel - $dpiGet.minScaleRel
                If ($absIndex -ge 0 -and $absIndex -lt $Script:DpiScalePercentage.Count) {
                    $dpiPercent = $Script:DpiScalePercentage[$absIndex]
                }
            }
        } Catch { <# DPI read is best-effort; fall back to 100 #> }

        # -- Determine if primary (position 0,0) --
        [bool]$isPrimary = ($null -ne $positionObj -and $positionObj.X -eq 0 -and $positionObj.Y -eq 0)

        # -- Rotation --
        [string]$rotation = [DisplayConfig.Helpers]::GetPathRotation($pathArray, $idx).ToString()

        [string]$friendlyName = $targetName.monitorFriendlyDeviceName
        If ([string]::IsNullOrWhiteSpace($friendlyName)) { $friendlyName = $sourceName.viewGdiDeviceName }

        $displayList.Add([PSCustomObject]@{
            FriendlyName  = $friendlyName
            DevicePath    = $targetName.monitorDevicePath
            GdiDeviceName = $sourceName.viewGdiDeviceName
            AdapterId     = $srcAdapterId
            SourceId      = $srcId
            TargetId      = $tgtId
            Resolution    = $resolutionObj
            Position      = $positionObj
            Scaling       = $dpiPercent
            IsPrimary     = $isPrimary
            Rotation      = $rotation
            RefreshRate   = $refreshRateObj
            SourceModeIdx = $srcModeIdx
            TargetModeIdx = $tgtModeIdx
        })
    }

    return $displayList.ToArray()
}

Function Resolve-AspectList {
    <#
    .SYNOPSIS
        Resolves -Include / -Exclude into a final list of aspects.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    Param(
        [string[]]$Include,
        [string[]]$Exclude
    )

    If ($Include -and $Include.Count -gt 0) { return $Include }
    If ($Exclude -and $Exclude.Count -gt 0) {
        return $Script:ValidAspectList | Where-Object { $Exclude -notcontains $_ }
    }
    return $Script:ValidAspectList
}

Function Build-DisplayEntry {
    <#
    .SYNOPSIS
        Builds a serializable hashtable for one display, filtered by aspects.
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param(
        [PSCustomObject]$Display,
        [string[]]$AspectList
    )

    [Hashtable]$entry = @{
        FriendlyName  = $Display.FriendlyName
        DevicePath    = $Display.DevicePath
        GdiDeviceName = $Display.GdiDeviceName
    }

    ForEach ($a in $AspectList) {
        Switch ($a) {
            'Resolution'     { $entry['Resolution']  = $Display.Resolution }
            'Scaling'        { $entry['Scaling']      = $Display.Scaling }
            'Position'       { $entry['Position']     = $Display.Position }
            'PrimaryDisplay' { $entry['IsPrimary']    = $Display.IsPrimary }
            'Rotation'       { $entry['Rotation']     = $Display.Rotation }
            'RefreshRate'    { $entry['RefreshRate']   = $Display.RefreshRate }
        }
    }

    return $entry
}

#endregion Private Helpers

#region Public Functions

Function Export-DisplayConfiguration {
    <#
    .SYNOPSIS
        Exports current display configuration to a JSON file.
    .DESCRIPTION
        Queries Windows for all active display paths using the CCD API and
        serializes the configuration to JSON.  You can limit which displays
        and which settings are captured via -DisplayName and -Include / -Exclude.
    .PARAMETER Path
        File path for the output JSON file.
    .PARAMETER DisplayName
        One or more display friendly names to include.  Supports tab completion.
    .PARAMETER Include
        Configuration aspects to include.  Cannot be used with -Exclude.
    .PARAMETER Exclude
        Configuration aspects to exclude.  Cannot be used with -Include.
    .EXAMPLE
        Export-DisplayConfiguration -Path .\displays.json
    .EXAMPLE
        Export-DisplayConfiguration -Path .\main.json -DisplayName 'DELL U2722D' -Include Resolution, Position
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$DisplayName,

        [ValidateSet('Resolution', 'Scaling', 'Position', 'PrimaryDisplay', 'Rotation', 'RefreshRate')]
        [string[]]$Include,

        [ValidateSet('Resolution', 'Scaling', 'Position', 'PrimaryDisplay', 'Rotation', 'RefreshRate')]
        [string[]]$Exclude
    )

    If ($Include -and $Exclude) {
        Throw 'Parameters -Include and -Exclude are mutually exclusive.'
    }

    [string[]]$aspectList = Resolve-AspectList -Include $Include -Exclude $Exclude
    [PSCustomObject[]]$displayList = Get-ConnectedDisplay

    If ($DisplayName -and $DisplayName.Count -gt 0) {
        $displayList = $displayList | Where-Object { $DisplayName -contains $_.FriendlyName }
    }

    If ($displayList.Count -eq 0) {
        Write-Warning 'No matching displays found. Nothing to export.'
        return
    }

    [System.Collections.Generic.List[Hashtable]]$entryList = @()
    ForEach ($d in $displayList) {
        $entryList.Add((Build-DisplayEntry -Display $d -AspectList $aspectList))
    }

    [Hashtable]$config = [ordered]@{
        Metadata = [ordered]@{
            ExportDate     = (Get-Date -Format 'o')
            ComputerName   = $env:COMPUTERNAME
            WindowsVersion = [Environment]::OSVersion.Version.ToString()
        }
        Included                 = $aspectList
        DisplayConfigurationList = $entryList.ToArray()
    }

    [Hashtable]$jsonParam = @{
        InputObject = $config
        Depth       = 10
    }
    ConvertTo-Json @jsonParam |
        Set-Content -Encoding UTF8 -LiteralPath $Path

    Write-Verbose "Exported $($entryList.Count) display(s) to '$Path'."
}

Function Import-DisplayConfiguration {
    <#
    .SYNOPSIS
        Restores display configuration from a previously exported JSON file.
    .DESCRIPTION
        Reads a JSON file produced by Export-DisplayConfiguration and applies
        the saved settings via the CCD API.  Displays present in the file but
        not currently connected are skipped with a warning.
    .PARAMETER Path
        Path to the JSON file to import.
    .PARAMETER DisplayName
        One or more display friendly names to restore.  Supports tab completion.
    .PARAMETER Include
        Configuration aspects to restore.  Cannot be used with -Exclude.
    .PARAMETER Exclude
        Configuration aspects to skip.  Cannot be used with -Include.
    .EXAMPLE
        Import-DisplayConfiguration -Path .\displays.json
    .EXAMPLE
        Import-DisplayConfiguration -Path .\displays.json -DisplayName 'DELL U2722D' -Include Resolution
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    Param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$Path,

        [string[]]$DisplayName,

        [ValidateSet('Resolution', 'Scaling', 'Position', 'PrimaryDisplay', 'Rotation', 'RefreshRate')]
        [string[]]$Include,

        [ValidateSet('Resolution', 'Scaling', 'Position', 'PrimaryDisplay', 'Rotation', 'RefreshRate')]
        [string[]]$Exclude
    )

    If ($Include -and $Exclude) {
        Throw 'Parameters -Include and -Exclude are mutually exclusive.'
    }

    # -- Read and parse --
    [PSCustomObject]$config = Get-Content -Raw -LiteralPath $Path |
        ConvertFrom-Json

    If (-not $config.DisplayConfigurationList) {
        Throw "The file '$Path' does not contain a valid display configuration."
    }

    # -- Determine which aspects to apply --
    [string[]]$requestedAspectList = Resolve-AspectList -Include $Include -Exclude $Exclude
    [string[]]$exportedAspectList = @($config.Included)
    [string[]]$aspectList = $requestedAspectList | Where-Object { $exportedAspectList -contains $_ }

    If ($aspectList.Count -eq 0) {
        Write-Warning 'No overlapping aspects between the file and the requested set. Nothing to apply.'
        return
    }

    # -- Get current display state --
    [PSCustomObject[]]$connectedDisplayList = Get-ConnectedDisplay

    # -- Get current CCD arrays (we will modify and reapply them) --
    [uint32]$pathCount = 0
    [uint32]$modeCount = 0
    [int]$hr = [DisplayConfig.Native]::GetDisplayConfigBufferSizes(
        [DisplayConfig.QDC]::OnlyActivePaths,
        [ref]$pathCount,
        [ref]$modeCount
    )
    If ($hr -ne 0) { Throw "GetDisplayConfigBufferSizes failed with HRESULT 0x$($hr.ToString('X8'))." }

    [DisplayConfig.DisplayConfigPathInfo[]]$pathArray = New-Object 'DisplayConfig.DisplayConfigPathInfo[]' $pathCount
    [DisplayConfig.DisplayConfigModeInfo[]]$modeArray = New-Object 'DisplayConfig.DisplayConfigModeInfo[]' $modeCount
    $hr = [DisplayConfig.Native]::QueryDisplayConfig(
        [DisplayConfig.QDC]::OnlyActivePaths,
        [ref]$pathCount,
        $pathArray,
        [ref]$modeCount,
        $modeArray,
        [IntPtr]::Zero
    )
    If ($hr -ne 0) { Throw "QueryDisplayConfig failed with HRESULT 0x$($hr.ToString('X8'))." }

    # Track DPI changes to apply after SetDisplayConfig
    [System.Collections.Generic.List[Hashtable]]$dpiChangeList = @()
    [bool]$anyChange = $false

    # -- Filter saved entries by -DisplayName if specified --
    [array]$savedDisplayList = @($config.DisplayConfigurationList)
    If ($DisplayName -and $DisplayName.Count -gt 0) {
        $savedDisplayList = $savedDisplayList | Where-Object { $DisplayName -contains $_.FriendlyName }
    }

    ForEach ($s in $savedDisplayList) {
        # Match to a connected display: DevicePath first, FriendlyName fallback
        [PSCustomObject]$connected = $connectedDisplayList |
            Where-Object { $_.DevicePath -eq $s.DevicePath } |
            Select-Object -First 1

        If (-not $connected) {
            $connected = $connectedDisplayList |
                Where-Object { $_.FriendlyName -eq $s.FriendlyName } |
                Select-Object -First 1
        }

        If (-not $connected) {
            Write-Warning "Display '$($s.FriendlyName)' is not connected. Skipping."
            Continue
        }

        [string]$displayLabel = "'$($connected.FriendlyName)' ($($connected.GdiDeviceName))"

        # Find the path entry for this connected display
        [int]$pathIdx = -1
        For ([int]$i = 0; $i -lt $pathCount; $i++) {
            If ([DisplayConfig.Helpers]::PathMatches($pathArray, $i, $connected.AdapterId, $connected.SourceId, $connected.TargetId)) {
                $pathIdx = $i
                Break
            }
        }
        If ($pathIdx -lt 0) {
            Write-Warning "Could not find CCD path for display $displayLabel. Skipping."
            Continue
        }

        [uint32]$srcIdx = [DisplayConfig.Helpers]::GetPathSourceModeIdx($pathArray, $pathIdx)
        [uint32]$tgtIdx = [DisplayConfig.Helpers]::GetPathTargetModeIdx($pathArray, $pathIdx)

        ForEach ($a in $aspectList) {
            Switch ($a) {
                'Resolution' {
                    If ($null -eq $s.Resolution) { Continue }
                    If (-not $PSCmdlet.ShouldProcess($displayLabel, "Set resolution to $($s.Resolution.Width)x$($s.Resolution.Height)")) { Continue }
                    If ($srcIdx -lt $modeCount) {
                        [DisplayConfig.Helpers]::SetSourceModeResolution($modeArray, $srcIdx, [uint32]$s.Resolution.Width, [uint32]$s.Resolution.Height)
                    }
                    If ($tgtIdx -lt $modeCount) {
                        [DisplayConfig.Helpers]::SetTargetModeActiveSize($modeArray, $tgtIdx, [uint32]$s.Resolution.Width, [uint32]$s.Resolution.Height)
                    }
                    $anyChange = $true
                }
                'Position' {
                    If ($null -eq $s.Position) { Continue }
                    If (-not $PSCmdlet.ShouldProcess($displayLabel, "Set position to ($($s.Position.X), $($s.Position.Y))")) { Continue }
                    If ($srcIdx -lt $modeCount) {
                        [DisplayConfig.Helpers]::SetSourceModePosition($modeArray, $srcIdx, [int]$s.Position.X, [int]$s.Position.Y)
                    }
                    $anyChange = $true
                }
                'PrimaryDisplay' {
                    If ($null -eq $s.IsPrimary) { Continue }
                    If ($s.IsPrimary -and -not $connected.IsPrimary) {
                        If (-not $PSCmdlet.ShouldProcess($displayLabel, 'Set as primary display')) { Continue }
                        If ($srcIdx -lt $modeCount) {
                            [int]$offsetX = [DisplayConfig.Helpers]::GetSourceModePositionX($modeArray, $srcIdx)
                            [int]$offsetY = [DisplayConfig.Helpers]::GetSourceModePositionY($modeArray, $srcIdx)
                            [DisplayConfig.Helpers]::OffsetAllSourcePositions($modeArray, $modeCount, $offsetX, $offsetY)
                        }
                        $anyChange = $true
                    }
                }
                'Rotation' {
                    If ($null -eq $s.Rotation) { Continue }
                    [DisplayConfig.DisplayConfigRotation]$targetRotation = [DisplayConfig.DisplayConfigRotation]::Identity
                    If ([Enum]::TryParse([string]$s.Rotation, [ref]$targetRotation)) {
                        If (-not $PSCmdlet.ShouldProcess($displayLabel, "Set rotation to $targetRotation")) { Continue }
                        [DisplayConfig.Helpers]::SetPathRotation($pathArray, $pathIdx, $targetRotation)
                        $anyChange = $true
                    }
                }
                'RefreshRate' {
                    If ($null -eq $s.RefreshRate) { Continue }
                    If (-not $PSCmdlet.ShouldProcess($displayLabel, "Set refresh rate to $($s.RefreshRate.Numerator)/$($s.RefreshRate.Denominator)")) { Continue }
                    If ($tgtIdx -lt $modeCount) {
                        [DisplayConfig.Helpers]::SetTargetModeRefreshRate($modeArray, $tgtIdx, [uint32]$s.RefreshRate.Numerator, [uint32]$s.RefreshRate.Denominator)
                    }
                    $anyChange = $true
                }
                'Scaling' {
                    If ($null -eq $s.Scaling) { Continue }
                    If (-not $PSCmdlet.ShouldProcess($displayLabel, "Set DPI scaling to $($s.Scaling)%")) { Continue }
                    $dpiChangeList.Add(@{
                        AdapterId = $connected.AdapterId
                        SourceId  = $connected.SourceId
                        Percent   = [int]$s.Scaling
                    })
                }
            }
        }
    }

    # -- Apply topology change --
    If ($anyChange) {
        [DisplayConfig.SDC]$sdcFlag = [DisplayConfig.SDC]::UseSuppliedDisplayConfig -bor
            [DisplayConfig.SDC]::Apply -bor
            [DisplayConfig.SDC]::AllowChanges -bor
            [DisplayConfig.SDC]::SaveToDatabase

        $hr = [DisplayConfig.Native]::SetDisplayConfig(
            $pathCount,
            $pathArray,
            $modeCount,
            $modeArray,
            $sdcFlag
        )
        If ($hr -ne 0) {
            Write-Error "SetDisplayConfig failed with HRESULT 0x$($hr.ToString('X8'))."
            return
        }
        Write-Verbose 'Display topology applied successfully.'
    }

    # -- Apply DPI scaling changes (must be done after SetDisplayConfig) --
    ForEach ($d in $dpiChangeList) {
        [int]$targetPercent = $d.Percent
        [int]$targetIndex = [Array]::IndexOf($Script:DpiScalePercentage, $targetPercent)
        If ($targetIndex -lt 0) {
            Write-Warning "DPI scale $targetPercent% is not a known Windows scale value. Skipping."
            Continue
        }

        # Read current to compute the relative step
        [DisplayConfig.DisplayConfigGetDpiScale]$dpiGet = [DisplayConfig.Helpers]::NewGetDpiScaleRequest($d.AdapterId, $d.SourceId)
        $hr = [DisplayConfig.Native]::DisplayConfigGetDeviceInfo([ref]$dpiGet)
        If ($hr -ne 0) {
            Write-Warning "Could not read current DPI scale (HRESULT 0x$($hr.ToString('X8'))). Skipping DPI change."
            Continue
        }

        [int]$targetRel = $targetIndex + $dpiGet.minScaleRel
        If ($targetRel -eq $dpiGet.curScaleRel) { Continue }

        [DisplayConfig.DisplayConfigSetDpiScale]$dpiSet = [DisplayConfig.Helpers]::NewSetDpiScaleRequest($d.AdapterId, $d.SourceId, $targetRel)
        $hr = [DisplayConfig.Native]::DisplayConfigSetDeviceInfo([ref]$dpiSet)
        If ($hr -ne 0) {
            Write-Warning "Failed to set DPI scale to $targetPercent% (HRESULT 0x$($hr.ToString('X8'))). This may require elevation."
        } Else {
            Write-Verbose "DPI scale set to $targetPercent%."
        }
    }
}

#endregion Public Functions

#region Argument Completers

[scriptblock]$Script:DisplayNameCompleter = {
    Param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # For Import, prefer reading names from the file if -Path is already bound
    If ($commandName -eq 'Import-DisplayConfiguration' -and $fakeBoundParameters.ContainsKey('Path')) {
        [string]$filePath = $fakeBoundParameters['Path']
        If (Test-Path -LiteralPath $filePath -PathType Leaf) {
            Try {
                [PSCustomObject]$json = Get-Content -Raw -LiteralPath $filePath | ConvertFrom-Json
                [string[]]$nameList = @($json.DisplayConfigurationList | ForEach-Object { $_.FriendlyName }) | Sort-Object -Unique
                ForEach ($n in $nameList) {
                    If ($n -like "$wordToComplete*") {
                        If ($n -match '\s') { "'$n'" } Else { $n }
                    }
                }
                return
            } Catch { <# Fall through to live query #> }
        }
    }

    # Default: query connected displays
    Try {
        [PSCustomObject[]]$displayList = Get-ConnectedDisplay
        [string[]]$nameList = @($displayList | ForEach-Object { $_.FriendlyName }) | Sort-Object -Unique
        ForEach ($n in $nameList) {
            If ($n -like "$wordToComplete*") {
                If ($n -match '\s') { "'$n'" } Else { $n }
            }
        }
    } Catch { <# Silently fail during tab completion #> }
}

Register-ArgumentCompleter -CommandName Export-DisplayConfiguration -ParameterName DisplayName -ScriptBlock $Script:DisplayNameCompleter
Register-ArgumentCompleter -CommandName Import-DisplayConfiguration -ParameterName DisplayName -ScriptBlock $Script:DisplayNameCompleter

#endregion Argument Completers
