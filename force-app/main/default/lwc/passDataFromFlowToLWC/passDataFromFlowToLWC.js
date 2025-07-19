import { LightningElement, api } from 'lwc';

export default class PassDataFromFlowToLWC extends LightningElement {
    //To set the data from the flow.
    @api inputDataFromFlow = [];

    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Title', fieldName: 'Title' },
        { label: 'Phone', fieldName: 'Phone' },
        { label: 'Email', fieldName: 'Email' }
    ];
}