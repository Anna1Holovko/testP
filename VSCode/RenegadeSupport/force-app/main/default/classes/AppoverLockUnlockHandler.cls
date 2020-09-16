public without sharing class AppoverLockUnlockHandler {
    Boolean hasBeenLocked;
    Boolean isLockedNow;
    String sObjectId;

    public AppoverLockUnlockHandler(String sObjectId){
        this.sObjectId = sObjectId;
        isLockedNow = hasBeenLocked = Approval.isLocked(sObjectId);
    }

    public Boolean unlockApprover(Boolean forceUnlock){
        Boolean result = true;
        if((hasBeenLocked && isLockedNow) || forceUnlock){
            if(!Approval.unlock(sObjectId, false).isSuccess()){
                result = false;
            }
        }
        isLockedNow = !result;
        return result; // !isLockedNow = !result;
    }

    public Boolean lockApprover(Boolean forceLock){
        Boolean result = true;                
        if((hasBeenLocked && !isLockedNow) || forceLock){
            if(!Approval.lock(sObjectId, false).isSuccess()){
                result = false;
            }
        }
        return isLockedNow = result;
    }
}