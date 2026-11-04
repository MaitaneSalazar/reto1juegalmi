import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReparacionPage } from './reparacion.page';

describe('ReparacionPage', () => {
  let component: ReparacionPage;
  let fixture: ComponentFixture<ReparacionPage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(ReparacionPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
