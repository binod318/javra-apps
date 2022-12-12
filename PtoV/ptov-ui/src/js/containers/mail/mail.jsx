import React from 'react';

import MailForm from './MailForm';

import Notification from '../../components/Notification';
import Wrapper from '../../components/Wrapper';
import Loader from '../../components/Loader';
import PVTable from '../../components/PVTable';

class Mail extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      crops: props.crops,
      mailList: props.mail,
      refresh: props.refresh,
      size: props.pagesize,
      page: props.pagenumber,
      total: props.total,
      selected: null,
      columnWidths: {
        configGroup: 300,
        configID: 120,
        cropCode: 120,
        recipients: 300,
        MailAction: 100
      },
      loading: false,
      mode: '',

      configID: '',
      configGroup: '',
      cropCode: '',
      recipients: ''
    };
  }

  componentDidMount() {
    const { mail, pagenumber, pagesize, crops } = this.props;

    if (crops.length === 0) {
      this.props.fetchCrops();
    }
    this.props.fetchData(pagenumber, pagesize);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.refresh != this.props.refresh) {
      this.setState({
        mailList: nextProps.mail,
        total: nextProps.total,
        refresh: nextProps.refresh,
      });
    }
    if (nextProps.crops.length != this.props.crops) {
      this.setState({
        crops: nextProps.crops
      });
    }

    if (nextProps.status.mail === 'procesing') {
      this.setState({ loading: true });
    } else {
      this.setState({ loading: false });
    }
  }

  changePage = pageNumber => {
    const { size } = this.state;
    this.props.fetchData(pageNumber, size);
  };

  emailEdit = index => {
    const { mailList } = this.state;
    this.setState({
      mode: 'edit',
      configID: mailList[index]['configID'] || '',
      configGroup: mailList[index]['configGroup'] || '',
      cropCode: mailList[index]['cropCode'] || '',
      recipients: mailList[index]['recipients'] || '',
    });
  };

  emailDelete = index => {
    const { mailList } = this.state;
    if (confirm('Are you sure to delete this Email?')) {
      this.props.deleteData(mailList[index]['configID']);
    }
  };

  emailAdd = index => {
    const { mailList } = this.state;
    this.setState({
      mode: 'add',
      configGroup: mailList[index]['configGroup'] || '',
      cropCode: '*'
    });
  };

  close = () => {
    this.setState({
      mode: '',
      configID: '',
      configGroup: '',
      cropCode: '',
      recipients: ''
    });
    this.props.resetError();
  };

  submit = (id, group, crop, email) => {
    this.props.postData();
  };

  dataStructure = {
    configGroup: { name: 'Group', grow: 0, sort: false, filter: false, width: 280 },
    cropCode: { name: 'Crop', grow: 0, sort: false, filter: false, width: 100 },
    recipients: { name: 'Email', grow: 1, sort: false, filter: false, width: 300 },
    MailAction: { name: 'Action', grow: 0, sort: false, filter: false, width: 100 }
  };

  render() {
    const { loading, page, size, total, columnWidths,
      mailList, mode, crops,
      configID, configGroup, cropCode, recipients
    } = this.state;
    return (
      <div>
        {mailList && mailList.length > 0 && (
          <PVTable
            sub={0}
            data={mailList}
            total={total}
            page={page}
            size={size}
            filterList={[]}
            structure={this.dataStructure}
            columnWidths={columnWidths}
            filterSort={() => {}}
            sorting={{}}
            filterData={() => {}}
            filterAdd={() => {}}
            filterRemove={() => {}}
            filterClear={() => {}}
            changePage={this.changePage}
            dataEdit={this.emailEdit}
            dataDelete={this.emailDelete}
            dataAdd={this.emailAdd}
          />
        )}

        {loading && <Loader />}

        <Wrapper display={mode}>
          <MailForm
            mode={mode}
            crops={crops}

            id={configID}
            group={configGroup}
            cropSelected={cropCode}
            email={recipients}

            close={this.close}
            submit={this.props.postData}
            errorMsg={this.props.mailError}
          />
        </Wrapper>

        {mode === '' && (
          <Notification where="mail" close={this.props.resetError} />
        )}
      </div>
    );
  }
}
export default Mail;