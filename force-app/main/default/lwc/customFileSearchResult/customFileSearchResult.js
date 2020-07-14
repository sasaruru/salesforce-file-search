import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
    { label: '名前', fieldName: 'link', type: 'url', typeAttributes:{label: { fieldName:'name'},  target: '_blank'}},
    { label: 'ファイル名', fieldName: 'contentLink', type: 'url', typeAttributes:{label: { fieldName:'title'}}},
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
        const data = fileList;
        console.log(data);
        this.data = data;
        this.tableLoadingState = false;
        this.tableDisp = true;
    }
    handleRowAction(event) {
        const row = event.detail.row;
        console.log(JSON.stringify(row));
        console.log(row.documentId);
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