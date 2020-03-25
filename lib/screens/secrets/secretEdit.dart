/*
 * Created by Ilan Rasekh on 2019/10/2
 * Copyright (c) 2019 Pseudorand Development. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nullpass/models/secret.dart';
import 'package:nullpass/screens/secrets/secretGenerate.dart';
import 'package:nullpass/services/datastore.dart';
import 'package:nullpass/services/logging.dart';
import 'package:nullpass/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';

enum SecretEditType { Create, Update }

class SecretEdit extends StatefulWidget {
  final Secret secret;
  final SecretEditType edit;

  SecretEdit({Key key, @required this.secret, @required this.edit})
      : super(key: key);

  @override
  _CreateSecretState createState() => _CreateSecretState();
}

class _CreateSecretState extends State<SecretEdit> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  Secret _secret;
  TextEditingController _passwordController = new TextEditingController();

  // Submit sends the new password data to the db to be saved then pop's up one level
  void submit(BuildContext context) async {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      // SAVE
      if (_secret.uuid == null || !isUUID(_secret.uuid.trim(), '4')) {
        _secret.uuid = (new Uuid()).v4();
      }
      NullPassDB helper = NullPassDB.instance;
      bool success = false;
      if (widget.edit == SecretEditType.Create) {
        var now = DateTime.now().toUtc();
        _secret.created = now;
        _secret.lastModified = now;
        success = await helper.insertSecret(_secret);
        Log.debug('inserted row(s) - $success');
        // await showSnackBar(context, 'Created!');
      } else if (widget.edit == SecretEditType.Update) {
        _secret.lastModified = DateTime.now().toUtc();
        success = await helper.updateSecret(_secret);
        Log.debug('updated row(s) - $success');
        // await showSnackBar(context, 'Updated!');
      }

      Navigator.pop(context, 'true');
    }
  }

  @override
  void initState() {
    super.initState();
    if (_secret == null) {
      _secret = (widget.secret != null
          ? widget.secret
          : new Secret(nickname: '', website: '', username: '', message: ''));
    }
  }

  void setPassword(String value) {
    setState(() {
      _secret.message = value;
    });
    _passwordController.text = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.edit == SecretEditType.Create)
            ? Text('New Secret')
            : ((widget.edit == SecretEditType.Update)
                ? Text('Update Secret')
                : Text('Secret Action')),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: new Container(
        padding: new EdgeInsets.all(20.0),
        child: new Form(
          key: this._formKey,
          child: new ListView(
            children: <Widget>[
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _secret.nickname = value;
                    });
                    Log.debug('new nickname ${_secret.nickname}');
                  },
                  initialValue: _secret.nickname,
                  decoration: InputDecoration(
                      labelText: 'Nickname', border: InputBorder.none),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'The Nickname field cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              FormDivider(),
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _secret.website = value;
                    });
                    Log.debug('new website ${_secret.website}');
                  },
                  initialValue: _secret.website,
                  decoration: InputDecoration(
                      labelText: 'Website', border: InputBorder.none),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'The Website field cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              FormDivider(),
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _secret.username = value;
                    });
                    Log.debug('new username ${_secret.username}');
                  },
                  initialValue: _secret.username,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'The Username field cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              FormDivider(),
              PasswordInput(
                onChange: (value) {
                  setState(() {
                    _secret.message = value;
                  });
                  Log.debug('new password ${_secret.message}');
                },
                controller: _passwordController,
                initialValue: _secret.message,
                setPassword: setPassword,
              ),
              FormDivider(),
              ListTile(
                title: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _secret.notes = value;
                    });
                    Log.debug('new notes ${_secret.notes}');
                  },
                  initialValue: _secret.notes,
                  decoration: InputDecoration(
                      labelText: 'Notes', border: InputBorder.none),
                ),
              ),
              FormDivider(),
              // Padding(padding: EdgeInsetsGeometry(2,2,2,2))
              ListTile(
                title: RaisedButton(
                  onPressed: () {
                    submit(context);
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return new SecretGenerate(inEditor: true);
              });
          if (result != null && result.toString().trim() != '') {
            _secret.message = result.toString();
            setPassword(_secret.message);
          }
        },
        tooltip: 'Generate',
        child: Icon(Icons.lock),
      ),
    );
  }
}

class PasswordInput extends StatefulWidget {
  final Function onChange;
  final String initialValue;
  final TextEditingController controller;
  final Function setPassword;

  PasswordInput(
      {Key key,
      @required this.onChange,
      @required this.controller,
      @required this.setPassword,
      this.initialValue = ''})
      : super(key: key);

  @override
  _PasswordInputState createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _visible = false;
  String _initialValue;
  TextEditingController _controller;
  Function _setPassword;

  @override
  void initState() {
    super.initState();
    if (_initialValue == null) {
      _initialValue = (widget.initialValue != null ? widget.initialValue : '');
    }
    _controller = widget.controller;
    _controller.text = _initialValue;
    _setPassword = widget.setPassword;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextFormField(
        controller: _controller,
        onChanged: (value) {
          widget.onChange(value);
        },
        decoration: InputDecoration(
          labelText: 'Password',
          border: InputBorder.none,
        ),
        // initialValue: _initialValue,
        obscureText: !_visible,
        validator: (value) {
          if (value.isEmpty) {
            return 'The Password field cannot be empty';
          }
          return null;
        },
      ),
      trailing: Container(
        width: 100,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: _visible
                  ? new Icon(FontAwesomeIcons.solidEye, size: 20)
                  : new Icon(FontAwesomeIcons.solidEyeSlash, size: 20),
              onPressed: () {
                // _initialValue = this.widget.
                setState(() {
                  _visible = !_visible;
                });
              },
            ),
            IconButton(
              // icon: new Icon(FontAwesomeIcons.lock, size: 20),
              icon: new Icon(Icons.lock),
              onPressed: () async {
                final result = await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return new SecretGenerate(inEditor: true);
                    });
                if (result != null && result.toString().trim() != '') {
                  _setPassword(result.toString());
                  setState(() {
                    _initialValue = result.toString();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}