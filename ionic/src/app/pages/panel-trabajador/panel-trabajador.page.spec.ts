import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PanelTrabajadorPage } from './panel-trabajador.page';

describe('PanelTrabajadorPage', () => {
  let component: PanelTrabajadorPage;
  let fixture: ComponentFixture<PanelTrabajadorPage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(PanelTrabajadorPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
