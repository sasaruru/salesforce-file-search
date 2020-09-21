import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjectInfo from '@salesforce/apex/CustomSearchController.getObjectInfo';

var columns = [
    { label: 'Preview', type: 'button', initialWidth: 135, typeAttributes: { label: 'Preview', name: 'preview', title: 'Click to View Details'}},
    { label: 'Name', fieldName: 'targetLink', type: 'url', sortable: true, typeAttributes:{label: { fieldName:'targetName'},  target: '_blank'}},
    { label: 'ファイル名', fieldName: 'documentLink', type: 'url', sortable: true, typeAttributes:{label: { fieldName:'documentTitle'}}},
    { label: '拡張子', fieldName: 'documentExtension', type: 'text' },
    { label: 'アップロード日', fieldName: 'lastUpdate', type: 'text'},
    // ここから任意項目
    
];

export default class CustomFileSearchResult extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track data = [];
    @track tableColumns = columns;
    @track tableLoadingState = true;
    @track tableDisp = false;
    @track sorted_by;
    @track sorted_direction;
    @api targetColumns;
    @api labels;

    connectedCallback() {
        // subscribe to searchKeyChange event
        registerListener('searchResult', this.handleResult, this);
    }

    disconnectedCallback() {
        // unsubscribe from searchKeyChange event
        unregisterAllListeners(this);
    }

    handleResult(params) {        
        // 0件の場合メッセージを表示し終了
        var fileList = params.result;
        if (fileList.length === 0){
            this.data = [];
            const evt = new ShowToastEvent({
                title: '検索結果',
                message: '検索結果が0件です。再度検索してください。',
                variant: 'info',
            });
            this.dispatchEvent(evt);
            return;
        }
        // オブジェクトは単一なので、プロパティから取得カラムのデータを取得
        // undifinedも含む
        if(this.targetColumns == null){
            this.tableLoadingState = false;
            this.tableDisp = true;
            this.data = params.result;
            return;
        }
        
        // クエリ生成し、fileListとマージ
        var ids = [];
        for (const fileObj of fileList){
            ids.push(fileObj.targetId);
        }
        let idSet = ids.filter(function (x, i, self) {
            return self.indexOf(x) === i;
            });
        // columnの再作成
        getObjectInfo({targetObject: params.targetObject, targetColumns: this.targetColumns, ids: idSet})
            .then(result=>{
                const cols = this.targetColumns.split(',');
                var resultList=[];
                for(var sarchResult of fileList){
                    var resultRow = sarchResult;
                    for(var col of cols){
                        resultRow[col] = result[sarchResult.targetId][col];
                    }
                    resultList.push(resultRow);
                }
                const tblColms = this.targetColumns.split(',');
                const tblLabels = this.labels.split(',');
                for (var i=0; i < tblColms.length; i++){
                    // { label: 'アップロード日', fieldName: 'lastUpdate', type: 'text', sortable: true,},
                    var c = {};
                    c.label = tblLabels[i];
                    c.fieldName = tblColms[i];
                    c.type = 'text';
                    c.sortable = true;
                    this.tableColumns.push(c);
                }
                this.tableLoadingState = false;
                this.data = resultList;
                this.tableDisp = true;
            })
            .catch(error =>{
                console.log(error);
                this.error = error;
            });     
    }
    handleRowAction(event) {
        const row = event.detail.row;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                selectedRecordId:row.documentId
            }
        });
    }
    handle_sort_data(event) {
        this.sorted_by = event.detail.fieldName;
        this.sorted_direction = event.detail.sortDirection;
        this.sort_data(event.detail.fieldName, event.detail.sortDirection);
    }
    sort_data(fieldname, direction) {
        let sorting_data = JSON.parse(JSON.stringify(this.data));
        // ソートするカラムの値を参照
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1 : -1;
        sorting_data.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.data = sorting_data;
    }
}
