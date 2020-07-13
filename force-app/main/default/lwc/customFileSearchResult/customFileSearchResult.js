import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

const columns = [
    { label: 'Id', fieldName: 'id' },
    { label: 'link', fieldName: 'link', type: 'url', typeAttributes:{label: { fieldName:'name'}, target: '_blank'}},
    { label: 'ファイル名', fieldName: 'title'},   
];

export default class CustomFileSearchResult extends LightningElement {
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
}