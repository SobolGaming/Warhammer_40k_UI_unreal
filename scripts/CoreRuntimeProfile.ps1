# Exact development snapshots, not a claim of interchangeable sessions.
function Get-CoreRuntimeProfile {
    param([ValidateSet('44.5.0', '44.3.33')][string]$Version = '44.5.0')
    $repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    if ($Version -eq '44.3.33') {
        return [pscustomobject]@{
            version = $Version
            commit = '5f509724da25a2f6ded0c2739a8e7c84bdf59c91'
            build = 'warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a'
            resourceCount = 3116
            sourceRoot = [IO.Path]::GetFullPath((Join-Path $repository '../Warhammer_40k_AI'))
            runtimeRoot = Join-Path $repository '.local/core-44.3.33'
            provenanceLeaf = '.e01-provenance.json'
            legacyProvenance = $true
        }
    }
    return [pscustomobject]@{
        version = $Version
        commit = '4f9bef0df2fb974d1285232a1009b8781926361d'
        build = 'warhammer40k-core-v2:runtime-tree-sha256-v1:0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba'
        resourceCount = 3130
        sourceRoot = Join-Path $repository '.local/core-source-44.5.0'
        runtimeRoot = Join-Path $repository '.local/core-44.5.0'
        provenanceLeaf = '.development-provenance.json'
        legacyProvenance = $false
    }
}
