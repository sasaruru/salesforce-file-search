import { LightningElement, track, wire } from 'lwc';
import searchRecords from '@salesforce/apex/CustomSearchController.searchRecords';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class CustomFileSearchForm extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    @track searchText;

    handleSearchTextChange(event){
        this.searchText = event.detail.value;
    }

    handleSearch() {
        let pageRef = this.pageRef;
        searchRecords({searchText : this.searchText})
            .then(result=>{
                fireEvent(pageRef, 'searchResult', result);
                this.error = undefined;
            })
            .catch(error =>{
                this.error = error;
            })

    }
}