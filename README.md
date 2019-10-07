# ActiveRecordEx

A library to make `ActiveRecord::Relation`s even more awesome.

[![Build Status](https://travis-ci.org/PagerDuty/active-record-ex.svg?branch=master)](https://travis-ci.org/PagerDuty/active-record-ex)

`ActiveRecordEx` is made of several [modules](#modules) that are used by `include`ing them on your `ActiveRecord` model classes.

#### Installation

Run
```
gem install active-record-ex
```
or add
```
gem 'active-record-ex', '~> 0.2.1'
```
to your `Gemfile`.

#### Compatibility

Currently, only ActiveRecord 3.2 is supported. However, other versions have not been tested and may be compatible.

## Modules

### `AssocOrdering`

Extends setters for `has_many` associations so that ordering of association arrays is persisted.

### `AssumeDestroy`

Changes the behavior of `accepts_nested_attributes_for` so that an explicit `_destroy: true` is not required to destroy an association model.

Instead, all models in the association will be destroyed if they are not included in the set of models used to update the association.

### `ManyToMany`

Allows chaining of calls to `has_many` and `belongs_to` relationships.

### `NillableFind`

Allows you to treat passing `nil` to a parent association as representing the "parent" of all of the child associations without a parent association.

### `PolymorphicBuild`

Allows choosing the subclass of a model in an association via a passed `:type` parameter, useful for `accepts_nested_attributes_for` on a polymorphic association.

## Development

Run tests with `rake test`.
  
