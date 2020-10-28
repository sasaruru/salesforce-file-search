public class CustomSearchController {
    /**
     * @param targetObject 検索対象オブジェクト
     * @param targetColumns 表示カラム
     * @param ids 検索対象のレコードID
     * @description レコードidから画面に表示する対象のオブジェクト情報を取得する.
     * @return IDと表示情報のMAP
     */
    @AuraEnabled
    public static Map<ID, SObject> getObjectInfo(String targetObject ,String targetColumns, List<String> ids ){
        // クエリ生成
        String q = 'SELECT Id, Name,' + targetColumns + ' FROM ' + targetObject + ' WHERE Id in :ids';
        List<SObject> sList = Database.query(q);
        Map<Id, SObject> result = new Map<Id, SObject>(Database.query(q));
        return result;
    }

    /**
     * @param obj 取得オブジェクトAPI名
     * @description オブジェクトのAPI名からラベル名を取得する.
     * @return オブジェクトのAPI名とラベル名のMAPリスト(key:label,value value:ラベル、API名)
     */
    @AuraEnabled
    public static List<Map<String, String>> getObjSelectOptions(List<String> objs){
        // mapの中身は
        // key : label, value
        // value: オブジェクトのAPI, ラベル名
        List<Map<String, String>> result = new List<Map<String, String>>();

        for(String obj : objs){
            Map<String, String> option = new Map<String, String>();
            option.put('value', obj);

            Map<String, sObjectType> sObjTypeMap = Schema.getGlobalDescribe();
            sObjectType sObjType = sObjTypeMap.get(obj);
            option.put('label', sObjType.getDescribe().getLabel());

            result.add(option);
        }
        return result;
    }
    /**
     * @param String Sobject名
     * @description オブジェクトのAPI名からレコードタイプ情報を取得ｓｙｒｙ
     * @return レコードタイプのAPI名とラベル名のMAPリスト(key:label,value value:ラベル、API名)
     */
    @AuraEnabled
    public static List<Map<String, String>> getObjRecordTypes(String sObjectName){
        List<Map<String, String>> result = new List<Map<String, String>>();

        List<RecordType> rtList = [SELECT Id,Name,DeveloperName FROM RecordType WHERE SobjectType= :sObjectName];
        for (RecordType rt : rtList){
            Map<String, String> resultMap = new Map<String, String>();
            resultMap.put('label',rt.Name);
            resultMap.put('value',rt.Id);
            result.add(resultMap);
        }
        return result;
    }
    /**
     * @param searchText SOSL検索キー
     * @param targetObject 検索対象オブジェクト
     * @param sortValue desc or asc (ソートは最終更新日)
     * @param recordTypeId レコードタイプID
     * @param limits 検索上限 ※SOSLの取得上限は2000
     * @description ファイルオブジェクトをSQSL検索し、対象オブジェクトと連結させて返却する.
     * @return 検索結果
     */
    @AuraEnabled
    public static List<Result> searchRecords(String searchText, String targetObject, String sortValue, String recordTypeId, Integer limits) {
        List<Result> results = new List<Result>();
        Integer counter= 0;
        if(searchText.length() < 2){
           return results; 
        }
        // ------------------------------
        //  SQSLによるコンテンツID取得
        // ------------------------------
        String query = 'find \'' + createSeachText(searchText) + '\' in all fields returning ContentVersion(Id,Title,ContentDocumentId,FileExtension,SystemModstamp' 
            + ' ORDER BY SystemModstamp ' + createSortText(sortValue) 
            + ' LIMIT ' + limits.format() +')';
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
        Map<String, String> documentEntityMap = new Map<String, String>();
        for (ContentDocumentLink cdLink : contentDocumentLinks){
            linkedEntityIds.add(cdLink.LinkedEntityId);
            //  LinkedEntityIdがtargetObjectのレコードIDならMapに追加する.
            ID objRecId = Id.valueOf(cdLink.LinkedEntityId);
            Schema.SObjectType sObjType = objRecId.getSObjectType();
            Schema.DescribeSObjectResult sObjResult = sObjType.getDescribe();
            String objName = sObjResult.getName();
            if(targetObject.equals(objName)){
                documentEntityMap.put(cdLink.ContentDocumentId, cdLink.LinkedEntityId);
            }            
        }
        System.debug('linkedEntityIds size : '+  linkedEntityIds.size());
        // ----------------------------------------------------------
        //  LinkedEntityIdから対象オブジェクトレコード取得
        // ----------------------------------------------------------    
        String q = 'SELECT Id, Name FROM ' + targetObject + ' WHERE Id in :linkedEntityIds';
        // レコードタイプ指定がある場合にWHERE句指定
        if(!'ALL'.equals(recordTypeId.toUpperCase())){
            q = q + ' AND RecordTypeId = ' + '\'' + recordTypeId + '\'';
        }
        Map<Id, SObject> objMap = new Map<ID, SObject>(Database.query(q));
        // 画面表示は検索されたファイル分のため取得したContentVersion事にオブジェクト作成
        for (ContentVersion contentVersion : cList){
            Result result = createResult(contentVersion, documentEntityMap, objMap);
            if(result != null){
                results.add(result);
            }
        }
        return results;
    }

    /**
     * @param baseSearchText 検索文字列
     * @description スペースをANDでつなぐ.
     * @return SOSL検索文字列
     */
    private static String createSeachText(String baseSearchText){
        // 全角スペースを半角スペースへ変換し、Trim
        baseSearchText = baseSearchText.replace('　',' ').trim();
        // 半角スペースをAND変換
        return baseSearchText.replace(' ',' AND ');
    }

    /**
     * @param baseSortText ソート文字列
     * @description ソート文字列を作成ASCでもDESCでもない場合はASCを返す.
     * @return SOSLソート文字列
     */
    private static String createSortText(String baseSortText){
        if('ASC'.equals(baseSortText.toUpperCase())){
            return baseSortText.toUpperCase();
        }
        if('DESC'.equals(baseSortText.toUpperCase())){
            return baseSortText.toUpperCase();
        }
        return 'ASC';
    }

    /**
     * @param contentVersion 
     * @param documentEntityMap key:ContentDocumentId value:LinkedEntityId
     * @param objMap オブジェクトMAP
     * @description 画面表示用の結果オブジェクトを作成する.
     * @return Resultオブジェクト
     */
    private static Result createResult(ContentVersion contentVersion ,Map<String, String> documentEntityMap,Map<Id, SObject> objMap){
        String documentId = contentVersion.ContentDocumentId;
        // breakするとloop全体が止まってしまう仕様らしく、
        // 仕方がないがネスト対応
        // contentVersionのDocumentIDからdocumentEntityMapを検索し、存在しないIDの場合はreturn
        String targetEntityId = documentEntityMap.get(documentId);
        if(targetEntityId == null || ''.equals(targetEntityId)){
            return null;
        }
        // 取得したentityIdから取得したobject情報を取得する
        SObject targetObject = objMap.get(targetEntityId);
        if(targetObject == null){
            return null;
        }
        return new Result(targetObject, contentVersion);
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
