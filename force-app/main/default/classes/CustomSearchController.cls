public class CustomSearchController {
   
    @AuraEnabled
    public static List<Result> searchRecords(String searchText, String targetObject) {
        List<Result> results = new List<Result>();
        Integer counter= 0;
        if(searchText.length() < 2){
           return results; 
        }
        // ------------------------------
        //  SQSLによるコンテンツID取得
        // ------------------------------
        String query = 'find \'' + searchText + '\' in all fields returning ContentVersion(Id,Title,ContentDocumentId,FileExtension,SystemModstamp)';
        System.Debug(query);
        List<List <sObject>> sobList =  search.query(query);
        // ドキュメントID取得
        List<ContentVersion> cList = (List<ContentVersion>)sobList[0];
        if(cList.size() == 0){
            return results;
        }
        // ----------------------------------------------------------
        //  contentVersionIdからcontentDocumentLinksのentityId取得
        // ----------------------------------------------------------    
        Set<String> contentVersionIds = new Set<String>();
        for (ContentVersion cv : cList){
            contentVersionIds.add(cv.ContentDocumentId);
        }
        System.Debug(contentVersionIds);

        // ドキュメントリンク取得
        List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId in :contentVersionIds];
        Set<String> linkedEntityIds = new Set<String>();
        for (ContentDocumentLink cdLink : contentDocumentLinks){
            linkedEntityIds.add(cdLink.LinkedEntityId);
        }
        // ----------------------------------------------------------
        //  LinkedEntityIdから対象オブジェクトレコード取得
        // ----------------------------------------------------------    
        String q = 'SELECT Id, Name FROM ' + targetObject + ' WHERE Id in :linkedEntityIds';
        List<SObject> objList = Database.query(q);
        // 画面表示は検索されたファイル分のため取得したContentVersion事にオブジェクト作成
        for (ContentVersion contentVersion : cList){
            Result result = createResult(contentVersion, contentDocumentLinks, objList);
            if(result != null){
                results.add(result);
            }
        }
        return results;
    }

    private static Result createResult(ContentVersion contentVersion,List<ContentDocumentLink> contentDocumentLinks,List<SObject> objLists){
        String targetRecordId = '';
        String documentId = contentVersion.ContentDocumentId;
        // breakするとloop全体が止まってしまう仕様らしく、
        // 仕方がないがネスト対応
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks){
            if(documentId.equals(contentDocumentLink.ContentDocumentId)){
                targetRecordId = contentDocumentLink.LinkedEntityId;
                for (SObject obj :objLists){
                    if(targetRecordId.equals((string)obj.get('Id'))){
                        System.debug('create result');
                        return new Result(obj, contentVersion);
                    }
                }               
            }
        }        
        return null;
    }
    @TestVisible public class Result {
        @AuraEnabled
        public String targetId;
        @AuraEnabled
        public String targetName;
        @AuraEnabled
        public String targetLink;
        @AuraEnabled
        public String documentTitle;
        @AuraEnabled
        public String documentLink;
        @AuraEnabled
        public String documentId;
        @AuraEnabled
        public String documentExtension;
        @AuraEnabled
        public String lastUpdate;
        
        public Result(SObject obj, ContentVersion contentVersion) {
            targetId = (string)obj.get('Id');
            targetLink = '/' + (string)obj.get('Id');
            targetName = (string)obj.get('Name');

            documentId = contentVersion.ContentDocumentId;
            documentLink = '/' + contentVersion.ContentDocumentId;
            documentTitle = contentVersion.Title;
            documentExtension = contentVersion.FileExtension;
            lastUpdate = contentVersion.SystemModstamp.format('yyyy/MM/dd HH:mm','Asia/Tokyo');
        }
    }
}
