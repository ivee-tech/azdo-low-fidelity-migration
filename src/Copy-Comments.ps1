Function Copy-Comments {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)][hashtable]$srcCtx,
        [Parameter(Mandatory=$true)][hashtable]$destCtx,
        [Parameter(Mandatory=$true)][string]$csvFilePath #format: oldId, newId
    )

[Reflection.Assembly]::LoadWithPartialName('Microsoft.TeamFoundation.Common')
[Reflection.Assembly]::LoadWithPartialName('Microsoft.TeamFoundation.Client')
[Reflection.Assembly]::LoadWithPartialName('Microsoft.TeamFoundation.WorkItemTracking.Client')

$oldTpc = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($srcCtx.orgUrl)
$newTpc = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($destCtx.orgUrl)
# $oldTpc
# $newTpc

$oldWorkItemStore = $oldTpc.GetService([Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore])
$newWorkItemStore = $newTpc.GetService([Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore])
# $oldWorkItemStore
# $newWorkItemStore

$list = Import-Csv $csvFilePath # -Delimiter "`t"

foreach($map in $list) {
    $map
    if($map.ReflectedWorkItemID -and $map.ID) {
        $oldItem = $oldWorkItemStore.GetWorkItem($map.ReflectedWorkItemID)
        $newItem = $newWorkItemStore.GetWorkItem($map.ID)

        Write-Host "Processing $($map.ReflectedWorkItemID) -> $($map.ID)" -ForegroundColor Cyan
    
        $comments = $oldItem.GetActionsHistory() | ? { $_.Description.length -gt 0 } | % { "[$($_.Tag) on $($_.ChangedDate)]: $($_.Description)" }
        if ($comments.Count -gt 0){
            Write-Host "   Porting $($comments.Count) comments..." -ForegroundColor Yellow
            foreach($comment in $comments) {
                Write-Host "      ...adding comment [$comment]"
                $newItem.History = $comment

                $newItem.Save()
            }
        }
    
        Write-Host "Done!" -ForegroundColor Green
    }
    else {
        Write-Host "Unable to migrate comments. Missing info: $map"
    }
}

Write-Host
Write-Host "Comments Migration complete"

}
