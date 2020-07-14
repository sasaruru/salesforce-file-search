import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Name', fieldName: 'objectLink', type: 'url', typeAttributes:{label: { fieldName:'name'},  target: '_blank'}},
    { label: 'ファイル名', fieldName: 'documentLink', type: 'url', typeAttributes:{label: { fieldName:'title'}}},
    { label: '最終更新日', fieldName: 'lastUpdate', type: 'text'},
    { label: 'Preview', type: 'button', initialWidth: 135, typeAttributes: { label: 'Preview', name: 'preview', title: 'Click to View Details'}},
];

export default class CustomFileSearchResult extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track data = [];
    @track columns = columns;
    @track tableLoadingState = true;
    @track tableDisp = false;

    connectedCallback() {
        // subscribe to searchKeyChange event
        registerListener('searchResult', this.handleResult, this);
    }

    disconnectedCallback() {
        // unsubscribe from searchKeyChange event
        unregisterAllListeners(this);
    }

    handleResult(fileList) {
        // 0件の場合メッセージを表示し終了
        if (fileList.length === 0){
            const evt = new ShowToastEvent({
                title: '検索結果',
                message: '検索結果が0件です。再度検索してください。',
                variant: 'info',
            });
            this.dispatchEvent(evt);
            return;
        }
        
        const data = fileList;
        this.data = data;
        this.tableLoadingState = false;
        this.tableDisp = true;
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
}